module GameRules
  class Bot
    def initialize(session:, state:, roll: nil, target: nil)
      @session = session
      @state = state.deep_dup
      @roll = roll&.to_i
      @target = target
    end

    def draw!
      if @state["mode"] == "ai"
        log("AI opponent placeholder: configured model would choose the Barbarian response here.")
        return persist!
      end

      deck = Array(@state["botDeck"])
      card = deck.shift
      unless card
        log("Bot deck is empty.")
        return persist!
      end

      @state["botDeck"] = deck
      log("Bot reveals #{card.fetch("title")}.")
      resolve_card(card)
      @state["discard"] ||= []
      @state["discard"] << card
      persist!
    end

    private

    def resolve_card(card)
      if card["area"].present? && neutral_area?(card["area"]) && @state.fetch("botNeutralActivations", 0).to_i < 2
        activate_area!(card["area"], "barbarian")
        @state["botNeutralActivations"] = @state.fetch("botNeutralActivations", 0).to_i + 1
        return
      end

      if card["area"].present? && (neutral_area?(card["area"]) || roman_controlled_area?(card["area"]))
        bot_political_action(card["area"], card)
        return
      end

      return if card["area"].present? && bot_move_from(card["area"])

      resolve_event(card)
    end

    def bot_political_action(area_id, card)
      area = Area.find_by(key: area_id)
      unless area && area.region.present? && !area.region.in?(["roman", "germania"])
        log("Bot political action had no valid target.")
        return
      end

      roll = d6
      if roll == 1 || roll <= card.fetch("ap").to_i
        area_units(area.key).each do |unit|
          unit["owner"] = "barbarian" unless unit["type"].in?(["roman", "german"])
        end
        log("Bot political action succeeds in #{area.name} on roll #{roll}.")
      else
        log("Bot political action fails in #{area.name} on roll #{roll}.")
      end
    end

    def bot_move_from(area_id)
      area = Area.find_by(key: area_id)
      return false unless area

      attackers = area_units(area.key).select { |unit| unit["owner"] == "barbarian" && current_strength(unit) >= 1 }
      return false if attackers.empty?

      targets = area.outgoing_borders.map(&:to_area).reject(&:sea?).select do |target|
        area_units(target.key).count { |unit| unit["owner"] != "barbarian" } == 1
      end
      target = targets.find { |candidate| roman_controlled_area?(candidate.key) } || targets.first
      return false unless target

      moved = attackers.first(2)
      moved.each { |unit| unit["location"] = target.key }
      log("Bot moves #{moved.map { |unit| unit.fetch("name") }.join(", ")} from #{area.name} to #{target.name}.")
      @state = GameRules::Battle.new(session: @session, state: @state).resolve!
      true
    end

    def resolve_event(card)
      if card.fetch("title") == "Baggage Train"
        return if bot_move_from("germania")

        @state["supply"] = [@state.fetch("supply", 0).to_i - 2, 0].max
        log("Bot Baggage Train reduces Roman supply by 2.")
        return
      end

      target = @target || random_target
      unless target
        log("Bot #{card.fetch("title")} found no valid revolt target.")
        return
      end

      activate_area!(target, "barbarian")
      if card.fetch("title") == "Massive Revolt" && @state.fetch("turn", 0).to_i >= 5
        vercingetorix = units["vercingetorix"]
        if vercingetorix
          vercingetorix["location"] = target
          vercingetorix["owner"] = "barbarian"
          log("Vercingetorix enters at #{area_name(target)}.")
        end
      end
      bot_move_from(target)
    end

    def random_target
      candidates = Area.order(:key).select do |area|
        area.region.present? && !area.region.in?(["roman", "germania"]) && (neutral_area?(area.key) || roman_controlled_area?(area.key))
      end
      candidates.sample&.key
    end

    def activate_area!(area_id, owner)
      area_units(area_id).select { |unit| unit["owner"] == "neutral" }.each do |unit|
        unit["owner"] = owner
        unit["step"] = 0
      end
      log("#{player_name(owner)} activates #{area_name(area_id)}.")
    end

    def neutral_area?(area_id)
      area_units(area_id).any? { |unit| unit["owner"] == "neutral" }
    end

    def roman_controlled_area?(area_id)
      area_units(area_id).any? { |unit| unit["owner"] == "roman" && unit["type"] != "roman" }
    end

    def current_strength(unit)
      strengths = unit["strengths"] || UnitType.find_by(key: unit["id"])&.strengths || []
      strengths[unit.fetch("step", 0).to_i].to_i
    end

    def d6
      @state["diceRolledThisTurn"] = true
      @state["undoStack"] = []
      return @roll if @roll&.between?(1, 6)

      rand(1..6)
    end

    def area_units(area_id)
      units.values.select { |unit| unit["location"] == area_id }
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

    def area_name(area_id)
      Area.find_by(key: area_id)&.name || area_id
    end

    def player_name(player)
      player == "roman" ? "Roman" : "Barbarian"
    end
  end
end
