module GameRules
  class ActionPhase
    NEUTRAL_ACTIVATION_LIMITS = { "roman" => 1, "barbarian" => 2 }.freeze

    class InvalidAction < StandardError; end

    def initialize(session:, state:)
      @session = session
      @state = state.deep_dup
    end

    def start_movement!
      raise InvalidAction, "End the current movement action before choosing another card action." if @state["movement"].present?

      card = action_card
      raise InvalidAction, card_prompt unless card

      @state["currentAction"] = "movement"
      @state["movement"] = {
        "player" => active_player,
        "cardId" => card.fetch("id"),
        "remaining" => card.fetch("ap").to_i,
        "areas" => [],
        "units" => {},
        "crossings" => {}
      }
      log("#{player_name(active_player)} is using #{card.fetch("title")} for movement: activate up to #{card.fetch("ap")} group#{card.fetch("ap").to_i == 1 ? "" : "s"}. Click a group area, then move its units.")
      persist!
    end

    def activate_movement_area!(area_id:)
      area_id = area_id.to_s
      movement = @state["movement"]
      raise InvalidAction, "No movement action is in progress." unless movement
      return persist! if Array(movement["areas"]).include?(area_id)

      area = Area.find_by(key: area_id)
      raise InvalidAction, "Unknown area #{area_id}." unless area

      movable_units = units.values.select { |unit| unit["location"] == area_id && unit["owner"] == active_player }
      raise InvalidAction, "#{area.name} has no #{player_name(active_player)} units to activate for movement." if movable_units.empty?

      remaining = movement["remaining"].to_i
      raise InvalidAction, "No movement group activations remain for this card." unless remaining.positive?

      movement["areas"] ||= []
      movement["areas"] << area_id
      movement["remaining"] = remaining - 1
      movement["units"] ||= {}
      movement["crossings"] ||= {}
      log("#{area.name} activated for movement. #{movement["remaining"]} group activation#{movement["remaining"] == 1 ? "" : "s"} remaining.")
      persist!
    end

    def supply!
      raise InvalidAction, "End the current movement action before choosing another card action." if @state["movement"].present?

      card = action_card
      raise InvalidAction, card_prompt unless card

      @state["currentAction"] = "supply"
      if active_player == "roman"
        @state["supply"] = [@state.fetch("supply", 0).to_i + card.fetch("ap").to_i * 2, 19].min
        log("Roman supply action with #{card.fetch("title")}: +#{card.fetch("ap").to_i * 2} supply.")
      else
        @state["supply"] = [@state.fetch("supply", 0).to_i - card.fetch("ap").to_i, 0].max
        log("Barbarian raid with #{card.fetch("title")}: -#{card.fetch("ap").to_i} Roman supply.")
      end
      persist!
    end

    def activate_neutral!
      raise InvalidAction, "End the current movement action before choosing another card action." if @state["movement"].present?

      card = action_card
      raise InvalidAction, card_prompt unless card
      raise InvalidAction, neutral_activation_limit_message if neutral_activation_limit_reached?

      area_id = card["area"]
      raise InvalidAction, "Event cards cannot activate neutral tribes." if area_id.blank?

      area = Area.find_by!(key: area_id)
      validate_roman_special_target!(area, action: "neutral activation") if active_player == "roman"

      @state["currentAction"] = "activate"
      activated_units = units.values.select { |unit| unit["location"] == area.key && unit["owner"] == "neutral" }
      activated_units.each do |unit|
        unit["owner"] = active_player
        unit["step"] = 0
      end
      record_neutral_activation_card(card)
      names = activated_units.map { |unit| unit.fetch("name") }.to_sentence
      plural = activated_units.many?
      log("#{names} #{plural ? "become" : "becomes"} #{plural ? player_name(active_player) : "a #{player_name(active_player)}"} #{plural ? "allies" : "ally"}.")
      persist!
    end

    def political!(area_id:, roll: nil)
      raise InvalidAction, "End the current movement action before choosing another card action." if @state["movement"].present?

      card = action_card
      raise InvalidAction, card_prompt unless card

      area = Area.find_by(key: area_id.to_s)
      raise InvalidAction, "That area is not a valid political target." unless political_target?(area)
      validate_roman_special_target!(area, action: "political action") if active_player == "roman"

      rolled = die_roll(roll)
      matching_card = card["area"] == area.key
      opposing_unit = units.values.any? do |unit|
        unit["location"] == area.key && unit["owner"] != active_player && unit["owner"] != "neutral"
      end
      modified = rolled
      modified -= 1 if matching_card
      modified += 1 if opposing_unit

      modifiers = []
      modifiers << "matching card -1" if matching_card
      modifiers << "opposing unit +1" if opposing_unit
      modifier_summary = modifiers.any? ? "#{modifiers.join(", ")}; " : ""

      @state["currentAction"] = "political"
      @state["diceRolledThisTurn"] = true
      @state["undoStack"] = []

      if modified <= card.fetch("ap").to_i
        political_units(area.key).each do |unit|
          unit["owner"] = active_player
          unit["location"] = unit["home"]
        end
        log("Political action succeeds in #{area.name}: rolled #{rolled}; #{modifier_summary}modified #{modified}; AP #{card.fetch("ap")}.")
        return resolve_political_battle!(area.key) if contested_area?(area.key)
      else
        log("Political action fails in #{area.name}: rolled #{rolled}; #{modifier_summary}modified #{modified}; AP #{card.fetch("ap")}.")
      end
      persist!
    end

    def event!(area_id: nil, unit_id: nil)
      raise InvalidAction, "End the current movement action before choosing another card action." if @state["movement"].present?

      card = action_card
      raise InvalidAction, card_prompt unless card

      @state["currentAction"] = "event"
      @state["massiveRevoltPlayed"] = true if card.fetch("title") == "Massive Revolt"
      if card.fetch("title") == "Baggage Train"
        if active_player == "roman"
          @state["supply"] = [@state.fetch("supply", 0).to_i + 5, 19].min
        else
          @state["supply"] = [@state.fetch("supply", 0).to_i - 2, 0].max
        end
        log("#{player_name(active_player)} resolves Baggage Train.")
        return persist!
      end

      if active_player == "roman"
        resolve_roman_revolt!(card, unit_id)
        return persist!
      end

      area_id = area_id.presence || @state["selectedArea"]
      raise InvalidAction, "Select an area, then play the revolt event." if area_id.blank?

      area = Area.find_by(key: area_id)
      raise InvalidAction, "Unknown area #{area_id}." unless area

      effective_title = effective_barbarian_revolt_title(card)
      if effective_title != card.fetch("title")
        log("Turn #{@state.fetch("turn", 0).to_i + 1}: #{card.fetch("title")} is treated as a #{effective_title}.")
      end
      activate_area!(area, active_player == "roman" ? "roman" : "barbarian")
      if effective_title == "Massive Revolt" && active_player == "barbarian"
        vercingetorix = units["vercingetorix"]
        if vercingetorix
          vercingetorix["location"] = area.key
          vercingetorix["owner"] = "barbarian"
        end
      end

      count = effective_title == "Massive Revolt" ? 3 : effective_title == "Major Revolt" ? 2 : 1
      log("#{effective_title} resolved for #{area.name}. Apply up to #{count} selected areas manually if needed.")
      persist!
    end

    private

    def resolve_roman_revolt!(card, unit_id)
      raise InvalidAction, "#{card.fetch("title")} has no Roman event effect implemented." unless revolt_event?(card)
      raise InvalidAction, "Select an active Barbarian-controlled tribe for #{card.fetch("title")}." if unit_id.blank?

      target = units[unit_id]
      raise InvalidAction, "Unknown tribe #{unit_id}." unless target
      raise InvalidAction, "#{target.fetch("name")} is not an active Barbarian-controlled tribe." unless roman_revolt_target?(target)

      home = target.fetch("home")
      home_units = units.values.select { |unit| unit["location"] == home && unit["id"] != unit_id }
      target["location"] = home
      if home_units.empty?
        target["owner"] = "neutral"
        target["step"] = 0
        log("#{card.fetch("title")}: #{target.fetch("name")} returns home to #{area_name(home)} and becomes neutral at full strength.")
      else
        target["owner"] = "barbarian"
        log("#{card.fetch("title")}: #{target.fetch("name")} returns home to #{area_name(home)} at current strength.")
      end
    end

    def revolt_event?(card)
      card.fetch("title").include?("Revolt")
    end

    def effective_barbarian_revolt_title(card)
      title = card.fetch("title")
      return title unless active_player == "barbarian" && title == "Massive Revolt"
      return "Minor Revolt" if @state.fetch("turn", 0).to_i.zero?

      title
    end

    def roman_revolt_target?(unit)
      unit["owner"] == "barbarian" &&
        unit["type"] == "barbarian" &&
        unit["home"].present? &&
        unit["location"].present? &&
        !unit["location"].in?(["eliminated", "offboard"]) &&
        current_strength(unit).positive? &&
        Area.find_by(key: unit["home"])&.region != "germania"
    end

    def current_strength(unit)
      strengths = Array(unit["strengths"])
      return 1 if strengths.empty?

      strengths[unit.fetch("step", 0).to_i].to_i
    end

    def action_card
      if @state["mode"] == "hotseat"
        @state["revealed"] ? @state.dig("committed", active_player) : @state["selectedCard"]
      else
        active_player == "roman" ? @state["selectedCard"] : nil
      end
    end

    def card_prompt
      @state["mode"] == "hotseat" ? "Select and commit a card first." : "Select a Roman card first."
    end

    def record_neutral_activation_card(card)
      @state["neutralActivationCards"] ||= { "roman" => [], "barbarian" => [] }
      @state["neutralActivationCards"][active_player] ||= []
      @state["neutralActivationCards"][active_player] << card
    end

    def neutral_activation_limit_reached?
      neutral_activation_count >= NEUTRAL_ACTIVATION_LIMITS.fetch(active_player)
    end

    def neutral_activation_count
      Array(@state.dig("neutralActivationCards", active_player)).length
    end

    def neutral_activation_limit_message
      limit = NEUTRAL_ACTIVATION_LIMITS.fetch(active_player)
      "#{player_name(active_player)} has reached the yearly neutral tribe activation limit (#{limit})."
    end

    def active_player
      @state.fetch("active")
    end

    def political_target?(area)
      area && area.region.present? && !area.region.in?(["roman", "germania"])
    end

    def validate_roman_special_target!(area, action:)
      if area.key == "germania"
        raise InvalidAction, "Romans may not use #{action} against Germania."
      end
      return unless area.region == "britannia" && !roman_legion_on_northern_coast?

      raise InvalidAction, "Romans need at least one legion in a port area connected to Oceanus Britannicus to use #{action} in Britannia."
    end

    def roman_legion_on_northern_coast?
      units.values.any? do |unit|
        next false unless unit["type"] == "roman" && unit["owner"] == "roman" && current_strength(unit).positive?

        area = Area.includes(outgoing_borders: :to_area).find_by(key: unit["location"])
        area&.outgoing_borders&.any? { |border| border.to_area.key == "oceanus_britannicus" }
      end
    end

    def political_units(area_id)
      units.values.select do |unit|
        unit["type"] == "barbarian" &&
          unit["home"] == area_id &&
          !unit["location"].in?(["eliminated", "offboard"]) &&
          current_strength(unit).positive?
      end
    end

    def contested_area?(area_id)
      owners = units.values.select { |unit| unit["location"] == area_id && current_strength(unit).positive? }
        .map { |unit| unit["owner"] }
        .uniq
      owners.include?("roman") && owners.include?("barbarian")
    end

    def resolve_political_battle!(area_id)
      GameRules::Battle.new(session: @session, state: @state, attacker: active_player).resolve!(area_id: area_id)
    end

    def die_roll(roll)
      roll = roll&.to_i
      return roll if roll&.between?(1, 6)

      rand(1..6)
    end

    def activate_area!(area, owner)
      validate_roman_special_target!(area, action: "neutral activation") if owner == "roman"

      units.values.select { |unit| unit["location"] == area.key && unit["owner"] == "neutral" }.each do |unit|
        unit["owner"] = owner
        unit["step"] = 0
      end
    end

    def units
      @state.fetch("units")
    end

    def persist!
      @session.update!(data: @state)
      @session.sync_from_data!
      @state
    end

    def log(message)
      @state["log"] ||= []
      @state["log"].unshift(message)
      @state["log"] = @state["log"].first(80)
    end

    def player_name(player)
      player == "roman" ? "Roman" : "Barbarian"
    end

    def area_name(area_id)
      Area.find_by(key: area_id)&.name || area_id.to_s.titleize
    end
  end
end
