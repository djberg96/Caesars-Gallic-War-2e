module GameRules
  class Bot
    def initialize(session:, state:, roll: nil, rolls: nil, target: nil)
      @session = session
      @state = state.deep_dup
      @roll = roll&.to_i
      @rolls = Array(rolls).map(&:to_i)
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
      action = resolve_card(card)
      @state["lastBotAction"] = {
        "cardId" => card.fetch("id"),
        "kind" => action
      }
      @state["discard"] ||= []
      @state["discard"] << card
      persist!
    end

    private

    def resolve_card(card)
      if card["area"].present? && neutral_area?(card["area"]) && @state.fetch("botNeutralActivations", 0).to_i < 2
        neutral_activation!(card["area"])
        @state["botNeutralActivations"] = @state.fetch("botNeutralActivations", 0).to_i + 1
        record_neutral_activation_card(card)
        return "neutral_tribe_activation"
      end

      if card["area"].present? && (neutral_area?(card["area"]) || roman_controlled_area?(card["area"]))
        bot_political_action(card["area"], card)
        return "political_action"
      end

      if card["area"].present?
        return "movement" if bot_move_from(card["area"])

        return resolve_failed_area_movement(card)
      end

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
        revolt_units(area.key).each do |unit|
          unit["owner"] = "barbarian"
          unit["location"] = unit.fetch("home")
        end
        log("Bot political action succeeds in #{area.name} on roll #{roll}.")
        resolve_bot_battle!(area.key, { "attacker" => "barbarian", "entries" => {} }) if contested_area?(area.key)
      else
        log("Bot political action fails in #{area.name} on roll #{roll}.")
      end
    end

    def bot_move_from(area_id, resolve_battle: true)
      area = Area.find_by(key: area_id)
      return false unless area
      return bot_move_from_germania(area, resolve_battle: resolve_battle) if area.key == "germania"

      attackers = area_units(area.key).select { |unit| unit["owner"] == "barbarian" && current_strength(unit) >= 1 }
      return false if attackers.empty?

      adjacent = area.outgoing_borders.map(&:to_area).reject(&:sea?)
      targets = targets_with_enemy_count(adjacent, 1)
      targets = targets_with_enemy_count(adjacent, 2) if targets.empty? && attackers.length >= 2
      target = targets.find { |candidate| roman_occupied_area?(candidate.key) } || targets.first
      return false unless target

      moved = attackers.first(2)
      activate_neutral_defenders!(target, attacker: "barbarian", entering_units: moved)
      moved.each { |unit| unit["location"] = target.key }
      log("Bot moves #{moved.map { |unit| unit.fetch("name") }.join(", ")} from #{area.name} to #{target.name}.")
      entry = queue_battle_entry!(target.key, attacker: "barbarian", origin: area.key, units: moved)
      resolve_bot_battle!(target.key, entry) if resolve_battle
      true
    end

    def bot_move_from_germania(area, resolve_battle: true)
      attackers = area_units(area.key).select do |unit|
        unit["owner"] == "barbarian" && unit["type"] == "german" && current_strength(unit) >= 2
      end
      return false if attackers.length < 2

      adjacent = area.outgoing_borders.map(&:to_area).reject(&:sea?)
      targets = adjacent.select do |target|
        area_units(target.key).count { |unit| unit["owner"] != "barbarian" }.between?(1, 2)
      end
      targets = targets.sort_by { |target| roman_occupied_area?(target.key) ? 0 : 1 }
      target_count = attackers.length >= 4 ? 2 : 1
      targets = targets.first(target_count)
      return false if targets.empty?

      moved = false
      targets.each_with_index do |target, index|
        group = attackers.slice(index * 2, 2)
        next if group.blank?

        activate_neutral_defenders!(target, attacker: "barbarian", entering_units: group)
        group.each { |unit| unit["location"] = target.key }
        log("Bot moves #{group.map { |unit| unit.fetch("name") }.join(", ")} from #{area.name} to #{target.name}.")
        queue_battle_entry!(target.key, attacker: "barbarian", origin: area.key, units: group)
        moved = true
      end
      resolve_next_bot_battle! if moved && resolve_battle
      moved
    end

    def targets_with_enemy_count(areas, count)
      areas.select do |target|
        area_units(target.key).count { |unit| unit["owner"] != "barbarian" } == count
      end
    end

    def resolve_failed_area_movement(card)
      if card["area"] != "germania" && bot_move_from("germania")
        log("Bot activates Germania because #{area_name(card.fetch("area"))} cannot attack.")
        return "movement"
      end

      target = @target || random_target
      unless target
        log("Bot #{card.fetch("title")} found no valid political target.")
        return "political_action"
      end

      log("Bot uses #{card.fetch("title")} for a fallback political action.")
      bot_political_action(target, card.merge("ap" => 3))
      "political_action"
    end

    def activate_neutral_defenders!(target, attacker:, entering_units:)
      defender = attacker == "roman" ? "barbarian" : "roman"
      entrant_names = entering_units.map { |unit| unit.fetch("name") }.join(", ")
      GameRules::Ariovistus.new(state: @state, roll: method(:d6)).resolve!(
        area_id: target.key,
        entering_units: entering_units
      ) if attacker == "barbarian"
      area_units(target.key).select { |unit| unit["owner"] == "neutral" }.each do |unit|
        unit["owner"] = defender
        log("#{unit.fetch("name")} joins the #{player_name(defender)} player as #{entrant_names} enters #{target.name}.")
      end
    end

    def queue_battle_entry!(area_id, attacker:, origin:, units:)
      pending = (@state["pendingBattleEntries"] ||= {})
      entry = (pending[area_id] ||= {
        "attacker" => attacker,
        "mainOrigin" => origin,
        "entries" => {}
      })
      units.each do |unit|
        entry["entries"][unit.fetch("id")] = origin
        unit["battleEntry"] = {
          "area" => area_id,
          "attacker" => attacker,
          "origin" => origin
        }
      end
      entry
    end

    def resolve_next_bot_battle!
      return if @state["battle"].present?

      pending = @state.fetch("pendingBattleEntries", {})
      area_id = pending.keys.find { |candidate| contested_area?(candidate) }
      entry = pending.fetch(area_id, {})
      resolve_bot_battle!(area_id, entry)
    end

    def resolve_bot_battle!(area_id, entry)
      return @state if @state["battle"].present?

      @state = GameRules::Battle.new(
        session: @session,
        state: @state,
        attacker: entry["attacker"],
        entry_origins: entry["entries"]
      ).resolve!(area_id: area_id, main_origin: entry["mainOrigin"])
    end

    def contested_area?(area_id)
      owners = area_units(area_id).map { |unit| unit["owner"] }.uniq
      owners.include?("roman") && owners.include?("barbarian")
    end

    def resolve_event(card)
      if card.fetch("title") == "Baggage Train"
        return "movement" if bot_move_from("germania")

        @state["supply"] = [@state.fetch("supply", 0).to_i - 2, 0].max
        log("Bot Baggage Train reduces Roman supply by 2.")
        return "event"
      end

      target = @target || random_target
      unless target
        log("Bot #{card.fetch("title")} found no valid revolt target.")
        return "event"
      end

      effective_title = effective_revolt_title(card)
      if effective_title != card.fetch("title")
        log("Turn #{@state.fetch("turn", 0).to_i + 1}: #{card.fetch("title")} is treated as a #{effective_title}.")
      end
      targets = revolt_targets(target, revolt_area_count(effective_title))
      targets.each { |area_id| activate_area!(area_id, "barbarian") }
      log("Bot revolt areas: #{targets.map { |area_id| area_name(area_id) }.join(", ")}.") if targets.many?
      if effective_title == "Minor Revolt"
        battle_area = targets.find { |area_id| contested_area?(area_id) }
        resolve_bot_battle!(battle_area, { "attacker" => "barbarian", "entries" => {} }) if battle_area
        return "event"
      end

      if effective_title == "Major Revolt"
        placement = minor_leaders.place_for_major_revolt!(targets)
        if placement
          leader = placement.fetch("leader")
          area = placement.fetch("area")
          log("#{leader.fetch("name")} enters at #{area.name}; this is now #{leader.fetch("name")}'s home area.")
        end
      end

      if effective_title == "Massive Revolt"
        vercingetorix = units["vercingetorix"]
        if vercingetorix
          vercingetorix["location"] = targets.first
          vercingetorix["owner"] = "barbarian"
          @state["massiveRevoltPlayed"] = true
          log("Vercingetorix enters at #{area_name(targets.first)}.")
        end
      end
      moved = targets.map { |area_id| bot_move_from(area_id, resolve_battle: false) }.any?
      resolve_next_bot_battle! if moved
      "event"
    end

    def effective_revolt_title(card)
      title = card.fetch("title")
      return "Minor Revolt" if title == "Major Revolt" && minor_leaders.both_in_play?
      return title unless title == "Massive Revolt"

      return "Major Revolt" if @state.fetch("turn", 0).to_i.zero?

      title
    end

    def revolt_area_count(title)
      return 3 if title == "Massive Revolt"
      return 2 if title == "Major Revolt"

      1
    end

    def revolt_targets(first, count)
      selected = [first]
      return selected if count == 1

      area = Area.find_by(key: first)
      adjacent = area ? area.outgoing_borders.map(&:to_area).reject(&:sea?).map(&:key) : []
      adjacent.select { |area_id| revolt_target_area?(area_id) && !selected.include?(area_id) }
        .sample(count - selected.length)
        .each { |area_id| selected << area_id }

      if selected.length < count
        remaining = Area.order(:key).reject(&:sea?).map(&:key).select do |area_id|
          revolt_target_area?(area_id) && !selected.include?(area_id)
        end
        remaining.sample(count - selected.length).each { |area_id| selected << area_id }
      end
      selected
    end

    def revolt_target_area?(area_id)
      return false if @state.fetch("turn", 0).to_i.zero? && area_id == "helvetii"

      neutral_area?(area_id) || roman_controlled_area?(area_id)
    end

    def random_target
      candidates = Area.order(:key).select do |area|
        area.region.present? && !area.region.in?(["roman", "germania"]) && (neutral_area?(area.key) || roman_controlled_area?(area.key))
      end
      candidates.sample&.key
    end

    def neutral_activation!(area_id)
      activated_units = area_units(area_id).select { |unit| unit["owner"] == "neutral" }
      activated_units.each do |unit|
        unit["owner"] = "barbarian"
        unit["step"] = 0
      end
      names = activated_units.map { |unit| unit.fetch("name") }.to_sentence
      plural = activated_units.many?
      log("#{names} #{plural ? "become Barbarian allies" : "becomes a Barbarian ally"}.")
    end

    def activate_area!(area_id, owner)
      revolt_units(area_id).each do |unit|
        unit["owner"] = owner
        unit["location"] = unit.fetch("home")
      end
      log("#{player_name(owner)} activates #{area_name(area_id)}.")
    end

    def revolt_units(area_id)
      units.values.select do |unit|
        unit["type"] == "barbarian" &&
          unit["home"] == area_id &&
          !unit["location"].in?(["eliminated", "offboard"]) &&
          current_strength(unit).positive?
      end
    end

    def record_neutral_activation_card(card)
      @state["neutralActivationCards"] ||= { "roman" => [], "barbarian" => [] }
      @state["neutralActivationCards"]["barbarian"] ||= []
      @state["neutralActivationCards"]["barbarian"] << card
    end

    def neutral_area?(area_id)
      revolt_units(area_id).any? { |unit| unit["owner"] == "neutral" }
    end

    def roman_controlled_area?(area_id)
      revolt_units(area_id).any? { |unit| unit["owner"] == "roman" }
    end

    def roman_occupied_area?(area_id)
      area_units(area_id).any? { |unit| unit["owner"] == "roman" }
    end

    def current_strength(unit)
      strengths = unit["strengths"] || UnitType.find_by(key: unit["id"])&.strengths || []
      strengths[unit.fetch("step", 0).to_i].to_i
    end

    def d6
      @state["diceRolledThisTurn"] = true
      @state["undoStack"] = []
      queued = @rolls.shift
      return queued if queued&.between?(1, 6)
      return @roll if @roll&.between?(1, 6)

      rand(1..6)
    end

    def area_units(area_id)
      units.values.select { |unit| unit["location"] == area_id }
    end

    def units
      @state.fetch("units")
    end

    def minor_leaders
      @minor_leaders ||= GameRules::MinorLeaders.new(state: @state)
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
      GameRules::PostGameReport.record!(@state, message)
    end

    def area_name(area_id)
      Area.find_by(key: area_id)&.name || area_id
    end

    def player_name(player)
      player == "roman" ? "Roman" : "Barbarian"
    end
  end
end
