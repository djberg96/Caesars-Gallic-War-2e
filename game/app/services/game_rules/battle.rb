module GameRules
  class Battle
    class InvalidAction < StandardError; end

    INITIATIVE_ORDER = { "A" => 1, "B" => 2, "C" => 3, "D" => 4 }.freeze

    def initialize(session:, state:, rolls: nil)
      @session = session
      @state = state.deep_dup
      @rolls = Array(rolls).map(&:to_i)
    end

    def resolve!(main_origin: nil)
      return advance_bot_and_persist! if battle

      area = contested_areas.first
      unless area
        log("No battles to resolve.")
        return persist!
      end

      @state["battle"] = build_battle(area, main_origin: main_origin)
      @state["movement"] = nil
      @state["currentAction"] = nil
      log("Battle board opened for #{area.name}.")
      advance_battle!
      advance_bot_actions!
      persist!
    end

    def act!(action:, unit_id: nil, target: nil)
      raise InvalidAction, "No battle is in progress." unless battle
      raise InvalidAction, "This battle is ready for regroup." if battle["phase"] == "regroup" && action != "regroup"

      case action.to_s
      when "fire"
        fire!(unit_id)
      when "pass"
        pass!(unit_id)
      when "retreat"
        retreat!(unit_id, target.presence || retreat_target(unit_id))
      when "fort"
        retreat_into_fort!(unit_id)
      when "regroup"
        regroup!(target.presence)
      else
        raise InvalidAction, "Unknown battle action #{action}."
      end

      advance_battle!
      advance_bot_actions!
      persist!
    end

    private

    def build_battle(area, main_origin: nil)
      attacker = @state.fetch("active", "roman")
      defender = attacker == "roman" ? "barbarian" : "roman"
      unit_ids = area_units(area.key)
        .select { |unit| unit["owner"].in?(["roman", "barbarian"]) && current_strength(unit).positive? }
        .map { |unit| unit.fetch("id") }

      attacker_ids = unit_ids.select { |id| unit(id)["owner"] == attacker }
      defender_ids = unit_ids.select { |id| unit(id)["owner"] == defender }
      main_origin ||= inferred_attacker_main_origin(area.key, attacker_ids)

      battle_data = {
        "area" => area.key,
        "round" => 1,
        "maxRounds" => area.key == "germania" ? 2 : 3,
        "phase" => "field",
        "attacker" => attacker,
        "defender" => defender,
        "activeUnit" => nil,
        "acted" => [],
        "actionResults" => [],
        "attackers" => attacker_ids,
        "defenders" => defender_ids,
        "mainOrigin" => main_origin,
        "reserves" => infer_reserves(area.key, attacker_ids, defender_ids, main_origin),
        "fort" => [],
        "halfHits" => {},
        "retreated" => [],
        "crossings" => {},
        "winner" => nil
      }
      assign_initial_fort_defenders!(area, battle_data)
      battle_data
    end

    def assign_initial_fort_defenders!(area, battle_data)
      return if area.fort_name.blank?
      return unless battle_data["defender"] == "barbarian"
      return if @state.fetch("mode", "hotseat") == "hotseat"

      candidates = battle_data["defenders"].reject { |id| battle_data["reserves"].include?(id) }
      home_defenders = candidates.select { |id| unit(id)["home"] == area.key }
      chosen = (home_defenders.presence || candidates).first(area.fort_level.to_i)
      return if chosen.empty?

      battle_data["fort"].concat(chosen)
      chosen.each { |id| log("#{unit(id).fetch("name")} starts inside #{area.fort_name}.") }
    end

    def inferred_attacker_main_origin(area_key, attacker_ids)
      origins = attacker_origins(area_key, attacker_ids)
      return nil if origins.empty?
      return origins.first if origins.one?

      nil
    end

    def attacker_origins(area_key, attacker_ids)
      attacker_ids.filter_map do |id|
        origin = movement_origin(id)
        origin if origin.present? && origin != area_key
      end.uniq
    end

    def infer_reserves(area_key, attacker_ids, defender_ids, main_origin)
      defender_reserves = defender_ids.select do |id|
        origin = movement_origin(id)
        origin.present? && origin != area_key
      end

      attacker_reserves = attacker_ids.select do |id|
        origin = movement_origin(id)
        origin.present? && origin != area_key && origin != main_origin
      end

      defender_reserves + attacker_reserves
    end

    def movement_origin(unit_id)
      moved = @state.dig("movement", "units") || {}
      moved.dig(unit_id, "origin")
    end

    def advance_bot_and_persist!
      advance_battle!
      advance_bot_actions!
      persist!
    end

    def advance_battle!
      return unless battle
      return if battle["phase"] == "regroup"

      eliminate_dead(battle_area.key)
      finish_battle_if_decided!
      return if battle["phase"] == "regroup"

      if active_queue.empty?
        start_next_round_or_regroup!
        return if battle["phase"] == "regroup"
      end

      battle["activeUnit"] = active_queue.first
    end

    def start_next_round_or_regroup!
      if battle["round"].to_i >= battle["maxRounds"].to_i
        battle["winner"] = battle["defender"]
        battle["phase"] = "regroup"
        battle["activeUnit"] = nil
        log("Battle in #{battle_area.name} reached the round limit. #{player_name(battle["attacker"])} must retreat; #{player_name(battle["defender"])} may regroup.")
        return
      end

      battle["round"] = battle["round"].to_i + 1
      battle["acted"] = []
      log("Battle in #{battle_area.name} continues to round #{battle["round"]}.")
    end

    def finish_battle_if_decided!
      fighters = live_combat_units
      return if both_sides?(fighters)

      winner = fighters.first&.fetch("owner")
      if winner
        battle["winner"] = winner
        battle["phase"] = "regroup"
        battle["activeUnit"] = nil
        log("#{player_name(winner)} wins the battle in #{battle_area.name}. Regroup victorious units or finish the battle.")
      else
        @state["battle"] = nil
      end
    end

    def fire!(unit_id)
      validate_active_unit!(unit_id)
      acting = unit(unit_id)
      enemies = targetable_enemies(acting)
      raise InvalidAction, "#{acting.fetch("name")} has no enemy units to fire on." if enemies.empty?

      rolls = Array.new(current_strength(acting)) { d6 }
      hits = rolls.count { |roll| roll <= acting.fetch("fire").to_i }
      applied = hits.positive? ? apply_hits(enemies, hits) : 0
      record_action_result({
        "type" => "fire",
        "unitId" => unit_id,
        "unitName" => acting.fetch("name"),
        "rolls" => rolls,
        "hits" => hits,
        "appliedHits" => applied
      })
      battle["acted"] << unit_id
      log("#{acting.fetch("name")} fires #{rolls.join(", ")} for #{hits} hit#{hits == 1 ? "" : "s"}.")
    end

    def pass!(unit_id)
      validate_active_unit!(unit_id)
      record_action_result({
        "type" => "pass",
        "unitId" => unit_id,
        "unitName" => unit(unit_id).fetch("name")
      })
      battle["acted"] << unit_id
      log("#{unit(unit_id).fetch("name")} passes in #{battle_area.name}.")
    end

    def retreat!(unit_id, target)
      validate_active_unit!(unit_id)
      raise InvalidAction, "#{unit(unit_id).fetch("name")} is inside the fort and cannot retreat from the field." if battle["fort"].include?(unit_id)

      target ||= retreat_target(unit_id)
      raise InvalidAction, "#{unit(unit_id).fetch("name")} has no legal retreat area." unless target

      border = border(battle_area.key, target)
      raise InvalidAction, "#{unit(unit_id).fetch("name")} cannot retreat to #{area_name(target)}." unless border

      apply_retreat_capacity!(target, border)
      unit(unit_id)["location"] = target
      battle["retreated"] << unit_id
      record_action_result({
        "type" => "retreat",
        "unitId" => unit_id,
        "unitName" => unit(unit_id).fetch("name"),
        "target" => target,
        "targetName" => area_name(target)
      })
      battle["acted"] << unit_id
      log("#{unit(unit_id).fetch("name")} retreats from #{battle_area.name} to #{area_name(target)}.")
    end

    def retreat_into_fort!(unit_id)
      validate_active_unit!(unit_id)
      raise InvalidAction, "#{battle_area.name} has no fort." unless battle_area.fort_name.present?
      raise InvalidAction, "Only defending units may retreat into the fort." unless unit(unit_id)["owner"] == battle["defender"]
      raise InvalidAction, "The fort at #{battle_area.name} is full." if battle["fort"].length >= battle_area.fort_level.to_i

      battle["fort"] << unit_id
      record_action_result({
        "type" => "fort",
        "unitId" => unit_id,
        "unitName" => unit(unit_id).fetch("name"),
        "fortName" => battle_area.fort_name
      })
      battle["acted"] << unit_id
      log("#{unit(unit_id).fetch("name")} withdraws into #{battle_area.fort_name}.")
    end

    def regroup!(target)
      raise InvalidAction, "No side has won this battle yet." unless battle["phase"] == "regroup"

      winners = live_units.select { |unit| unit["owner"] == battle["winner"] && unit["location"] == battle_area.key }
      if target.present?
        border_to_target = border(battle_area.key, target)
        raise InvalidAction, "Victorious units cannot regroup to #{area_name(target)}." unless border_to_target
        raise InvalidAction, "Victorious units cannot regroup into an enemy or neutral occupied area." if non_friendly_units_in?(target, battle["winner"])
        apply_regroup_capacity!(target, border_to_target, winners.length)

        winners.each { |winner| winner["location"] = target }
        log("#{player_name(battle["winner"])} regroups #{winners.length} unit#{winners.length == 1 ? "" : "s"} from #{battle_area.name} to #{area_name(target)}.")
      else
        log("#{player_name(battle["winner"])} holds #{battle_area.name} after battle.")
      end

      @state["battle"] = nil
    end

    def advance_bot_actions!
      guard = 0
      while battle && battle["phase"] == "field" && bot_controls_active_unit? && guard < 20
        guard += 1
        bot_act!
        advance_battle!
      end
    end

    def bot_controls_active_unit?
      active_id = battle["activeUnit"]
      return false unless active_id
      return false if @state.fetch("mode", "hotseat") == "hotseat"

      unit(active_id)["owner"] == "barbarian"
    end

    def record_action_result(result)
      battle["lastAction"] = result
      battle["actionResults"] ||= []
      battle["actionResults"] << result
      battle["actionResults"] = battle["actionResults"].last(6)
    end

    def bot_act!
      active_id = battle.fetch("activeUnit")
      acting = unit(active_id)
      if bot_should_retreat?(acting) && !battle["fort"].include?(active_id)
        target = bot_retreat_target(acting)
        if target == "fort"
          retreat_into_fort!(active_id)
        elsif target
          retreat!(active_id, target)
        else
          fire!(active_id)
        end
      else
        fire!(active_id)
      end
    rescue InvalidAction
      fire!(active_id)
    end

    def bot_should_retreat?(acting)
      enemy_strength = owner_strength(acting["owner"] == "roman" ? "barbarian" : "roman")
      own_strength = owner_strength(acting["owner"])
      return false unless own_strength.positive?

      if acting["owner"] == battle["attacker"]
        return enemy_strength > own_strength
      end

      enemy_strength >= own_strength * 2
    end

    def bot_retreat_target(acting)
      if acting["owner"] == battle["defender"] && acting["home"] == battle_area.key && battle_area.fort_name.present? && battle["fort"].length < battle_area.fort_level.to_i
        return "fort"
      end

      retreat_target(acting.fetch("id"))
    end

    def active_queue
      eligible = live_combat_units.reject { |unit| battle["acted"].include?(unit.fetch("id")) || reserve_waiting?(unit) }
      eligible.sort_by { |unit| initiative_sort_key(unit) }.map { |unit| unit.fetch("id") }
    end

    def reserve_waiting?(unit)
      battle["round"].to_i == 1 && battle["reserves"].include?(unit.fetch("id"))
    end

    def initiative_sort_key(unit)
      side_order = unit["owner"] == battle["defender"] ? 0 : 1
      unit["id"] == "legion_x" ? [0, side_order, unit["name"]] : [effective_initiative_value(unit), side_order, unit["name"]]
    end

    def effective_initiative_value(unit)
      value = INITIATIVE_ORDER.fetch(unit["initiative"], 5)
      return value unless unit["owner"] == battle["defender"] && battle["fort"].include?(unit.fetch("id"))

      [value - 1, 1].max
    end

    def validate_active_unit!(unit_id)
      raise InvalidAction, "It is not #{unit(unit_id).fetch("name")}'s turn to act." unless battle["activeUnit"] == unit_id
    end

    def targetable_enemies(acting)
      live_combat_units.select { |other| enemy?(other["owner"], acting["owner"]) }
    end

    def apply_hits(enemies, hits)
      applied = 0
      hits.times do
        target = enemies
          .select { |unit| unit["location"] != "eliminated" && current_strength(unit).positive? }
          .max_by { |unit| current_strength(unit) }
        return applied unless target

        if battle["fort"].include?(target.fetch("id"))
          battle["halfHits"][target.fetch("id")] = battle["halfHits"].fetch(target.fetch("id"), 0).to_i + 1
          next unless battle["halfHits"][target.fetch("id")].to_i >= 2

          battle["halfHits"][target.fetch("id")] = battle["halfHits"][target.fetch("id")].to_i - 2
        end
        target["step"] = target.fetch("step", 0).to_i + 1
        applied += 1
      end
      applied
    end

    def eliminate_dead(area_key)
      area_units(area_key).each do |unit|
        next if current_strength(unit).positive?

        unit["location"] = "eliminated"
        remove_from_battle!(unit.fetch("id"))
        if unit["id"] == "legion_x"
          log("Caesar has been killed. Barbarian instant victory.")
        elsif unit["type"] == "roman"
          @state["vp"] = [@state.fetch("vp", 0).to_i - 5, 0].max
          log("#{unit.fetch("name")} eliminated. Roman VP -5.")
        elsif unit["type"] == "german"
          @state["vp"] = @state.fetch("vp", 0).to_i + (unit["id"] == "ariovistus" ? 2 : 1)
          log("#{unit.fetch("name")} eliminated. Roman VP increases.")
        elsif unit["id"] == "vercingetorix"
          @state["vp"] = @state.fetch("vp", 0).to_i + 3
          log("Vercingetorix eliminated. Roman VP +3.")
        else
          log("#{unit.fetch("name")} eliminated.")
        end
      end
    end

    def remove_from_battle!(unit_id)
      %w[attackers defenders reserves fort retreated acted].each do |key|
        battle[key]&.delete(unit_id)
      end
    end

    def retreat_target(unit_id)
      acting = unit(unit_id)
      battle_area.outgoing_borders.map(&:to_area).reject(&:sea?).map(&:key).find do |target|
        next false if target == "germania" && acting["type"] != "german"
        next false if non_friendly_units_in?(target, acting["owner"])

        true
      end
    end

    def apply_retreat_capacity!(target, border)
      capacity = border.capacity
      return unless capacity

      key = "#{battle_area.key}->#{target}"
      used = battle["crossings"].fetch(key, 0).to_i
      raise InvalidAction, "No more than #{capacity} unit#{capacity == 1 ? "" : "s"} may retreat across #{battle_area.name} to #{area_name(target)} this round." if used + 1 > capacity

      battle["crossings"][key] = used + 1
    end

    def apply_regroup_capacity!(target, border, count)
      capacity = border.capacity
      return unless capacity

      raise InvalidAction, "No more than #{capacity} unit#{capacity == 1 ? "" : "s"} may regroup across #{battle_area.name} to #{area_name(target)}." if count > capacity
    end

    def contested_areas
      Area.order(:key).select do |area|
        owners = area_units(area.key).map { |unit| unit["owner"] }.reject { |owner| owner == "neutral" }
        owners.include?("roman") && owners.include?("barbarian")
      end
    end

    def both_sides?(fighters)
      owners = fighters.map { |unit| unit["owner"] }
      owners.include?("roman") && owners.include?("barbarian")
    end

    def live_field_units
      live_units.select do |unit|
        unit["location"] == battle_area.key && !battle["fort"].include?(unit.fetch("id"))
      end
    end

    def live_combat_units
      live_units.select { |unit| unit["location"] == battle_area.key }
    end

    def live_units
      units.values.select { |unit| unit["owner"].in?(["roman", "barbarian"]) && current_strength(unit).positive? }
    end

    def area_units(area_key)
      units.values.select { |unit| unit["location"] == area_key }
    end

    def owner_strength(owner)
      live_combat_units.select { |unit| unit["owner"] == owner }.sum { |unit| current_strength(unit) }
    end

    def current_strength(unit)
      strengths = unit["strengths"] || UnitType.find_by(key: unit["id"])&.strengths || []
      strengths[unit.fetch("step", 0).to_i].to_i
    end

    def non_friendly_units_in?(area_key, owner)
      area_units(area_key).any? { |other| other["owner"] != owner }
    end

    def enemy?(left, right)
      left != "neutral" && right != "neutral" && left != right
    end

    def border(from, to)
      Border.includes(:to_area).find_by(from_area: Area.find_by(key: from), to_area: Area.find_by(key: to))
    end

    def battle_area
      @battle_area = Area.find_by!(key: battle.fetch("area")) if @battle_area&.key != battle.fetch("area")
      @battle_area
    end

    def battle
      @state["battle"]
    end

    def unit(id)
      units.fetch(id)
    rescue KeyError
      raise InvalidAction, "Unknown unit #{id}."
    end

    def units
      @state.fetch("units")
    end

    def d6
      @state["diceRolledThisTurn"] = true
      @state["undoStack"] = []
      @rolls.shift || rand(1..6)
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

    def area_name(key)
      Area.find_by(key: key)&.name || key
    end

    def player_name(player)
      player == "roman" ? "Roman" : "Barbarian"
    end
  end
end
