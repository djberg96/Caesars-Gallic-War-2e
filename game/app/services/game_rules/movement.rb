module GameRules
  class Movement
    class InvalidMove < StandardError; end

    def initialize(session:, state:, rolls: nil)
      @session = session
      @state = state.deep_dup
      @rolls = Array(rolls).map(&:to_i)
    end

    def move!(unit_id:, target:)
      @unit_id = unit_id.to_s
      @target = target.to_s
      @unit = unit(@unit_id)
      @from = @unit.fetch("location")

      validate_control!
      validate_start_area!
      plan = move_plan
      raise InvalidMove, invalid_move_reason unless plan

      apply_capacity!(plan)
      apply_move!(plan)
      persist!
    end

    private

    def validate_control!
      return if @unit["owner"] == active_player

      raise InvalidMove, "#{unit_name} is not controlled by the active player."
    end

    def validate_start_area!
      raise InvalidMove, "Play a card for movement before moving blocks." unless movement
      return if movement_area_activated?(movement_origin)

      raise InvalidMove, "Activate #{area_name(movement_origin)} for movement before moving #{unit_name}."
    end

    def move_plan
      return nil unless target_area
      return nil if target_area.sea?
      return nil if offboard?(@from)
      return nil if @from == @target
      return nil unless legal_area_for_unit?
      return nil unless can_unit_move_this_card?
      return nil if off_map_departure? && @target != "transalpine_gaul"

      direct_border = border(@from, @target)
      if direct_border
        if border_has_capacity?(@from, @target, direct_border)
          return { "force" => false, "steps" => [[@from, @target, direct_border]] }
        end

        return nil
      end
      return nil if retreat_movement?
      return naval_route if naval_route

      force_route
    end

    def invalid_move_reason
      return "#{@target} is not a known area." unless target_area
      return "#{unit_name} cannot move into #{area_name(@target)} because it is a sea area." if target_area.sea?
      return "#{unit_name} is not on the map." if offboard?(@from)
      return "#{unit_name} is already in #{area_name(@target)}." if @from == @target
      return illegal_area_reason unless legal_area_for_unit?
      return "#{unit_name} may only move from the Roman Off-Map area to Transalpine Gaul." if off_map_departure? && @target != "transalpine_gaul"
      return movement_limit_reason unless can_unit_move_this_card?
      return "#{unit_name} cannot retreat more than one area." if retreat_movement?

      direct_border = border(@from, @target)
      if direct_border && !border_has_capacity?(@from, @target, direct_border)
        capacity = direct_border.capacity
        return "No more than #{capacity} unit#{capacity == 1 ? "" : "s"} may cross #{area_name(@from)} to #{area_name(@target)} this movement action."
      end

      return "Roman naval invasions require 1 supply per group." if naval_route_available? && naval_invasion_cost_due? && !supply.positive?
      return "#{unit_name} cannot force march." unless roman_legion?
      return "Roman legions need 1 supply to force march." unless supply.positive?
      return "#{unit_name} cannot force march after it has already moved." if movement_units.dig(@unit_id, "steps").to_i.positive?

      "#{unit_name} has no legal route from #{area_name(@from)} to #{area_name(@target)}."
    end

    def illegal_area_reason
      return "Only Roman blocks may move to the Roman off-map area." if @target == "roman_off_map"
      return "Only Roman and German blocks may move to Germania." if @target == "germania"

      "#{unit_name} cannot enter #{area_name(@target)}."
    end

    def movement_limit_reason
      moved = movement_units[@unit_id]
      if off_map_departure? && !moved && movement.fetch("remaining", 0).to_i <= 0
        return "No group activations remain to move #{unit_name} from the Roman Off-Map area."
      end
      return "Activate #{area_name(@from)} for movement before moving #{unit_name}." unless moved
      return "#{unit_name} has already retreated from this battle." if retreat_movement? && moved["stopped"]
      return "#{unit_name} has already finished movement for this card." if moved["stopped"]
      return "#{unit_name} has already moved two areas for this card." if moved["steps"].to_i >= 2
      return "#{unit_name} cannot move more than one area." unless roman_legion?

      "Roman legions need 1 supply to move a second area."
    end

    def can_unit_move_this_card?
      return false unless movement

      moved = movement_units[@unit_id]
      if off_map_departure? && !moved
        return movement_area_activated?(@from) && movement.fetch("remaining", 0).to_i.positive?
      end
      return movement_area_activated?(@from) unless moved
      return false if moved["stopped"] || moved["steps"].to_i >= 2
      return false if retreat_movement?

      roman_legion? && supply.positive?
    end

    def force_route
      return nil if retreat_movement?
      return nil if off_map_departure?
      return nil unless roman_legion?
      return nil unless supply.positive?
      return nil if movement_units.dig(@unit_id, "steps").to_i.positive?

      from_area.outgoing_borders.includes(:to_area).each do |first_border|
        middle = first_border.to_area
        next if middle.key == @target || middle.sea?
        next if area_has_stopper?(middle.key, @unit["owner"])

        second_border = border(middle.key, @target)
        next unless second_border
        next if second_border.to_area.sea?
        next unless border_has_capacity?(@from, middle.key, first_border)
        next unless border_has_capacity?(middle.key, @target, second_border)

        return {
          "force" => true,
          "via" => middle.key,
          "steps" => [[@from, middle.key, first_border], [middle.key, @target, second_border]]
        }
      end

      nil
    end

    def border_has_capacity?(from, to, border)
      capacity = border.capacity
      return true unless capacity

      movement.fetch("crossings", {}).fetch("#{from}->#{to}", 0).to_i < capacity
    end

    def naval_route
      return @naval_route if defined?(@naval_route)

      @naval_route = nil
      return unless from_area.port? && target_area.port?
      return if movement_units.dig(@unit_id, "steps").to_i.positive?

      first_border = from_area.outgoing_borders.includes(:to_area).find do |candidate|
        candidate.kind == "naval" && candidate.to_area.sea? && border(candidate.to_area.key, @target)&.kind == "naval"
      end
      return unless first_border

      sea = first_border.to_area
      second_border = border(sea.key, @target)
      return unless second_border&.kind == "naval"
      return if roman_legion? && naval_invasion_cost_due? && !supply.positive?

      @naval_route = {
        "force" => false,
        "naval" => true,
        "entry" => @from,
        "steps" => [[@from, sea.key, first_border], [sea.key, @target, second_border]]
      }
    end

    def naval_route_available?
      return false unless from_area.port? && target_area.port?
      return false if movement_units.dig(@unit_id, "steps").to_i.positive?

      from_area.outgoing_borders.includes(:to_area).any? do |candidate|
        candidate.kind == "naval" && candidate.to_area.sea? && border(candidate.to_area.key, @target)&.kind == "naval"
      end
    end

    def apply_capacity!(plan)
      crossings = movement["crossings"] ||= {}

      if plan["naval"] && movement.fetch("navalDepartures", {}).fetch(@from, 0).to_i >= 2
        raise InvalidMove, "No more than 2 units may make a naval move from #{area_name(@from)} in one movement action."
      end

      plan.fetch("steps").each do |from, to, border|
        capacity = border.capacity
        next unless capacity

        key = "#{from}->#{to}"
        used = crossings[key].to_i
        next if used + 1 <= capacity

        raise InvalidMove, "No more than #{capacity} unit#{capacity == 1 ? "" : "s"} may cross #{area_name(from)} to #{area_name(to)} this movement action."
      end
    end

    def apply_move!(plan)
      consume_off_map_activation!
      @unit["location"] = @target
      record_unit_movement!(plan)
      record_yearly_objective_progress!(plan)
      charge_naval_invasion!(plan)
      activate_neutral_units_in_target!

      message = "#{unit_name} moved to #{area_name(@target)}"
      message += " by forced march through #{area_name(plan.fetch("via"))}" if plan["force"]
      message += " by naval movement" if plan["naval"]
      log("#{message}.")
      @state["selectedUnit"] = nil
    end

    def record_yearly_objective_progress!(plan)
      return unless roman_legion?
      return unless ActiveModel::Type::Boolean.new.cast(@state.dig("options", "yearlyObjectives"))

      progress = @state["yearlyObjectiveProgress"] ||= {}
      destinations = plan.fetch("steps").map { |_from, to, _border| to }
      if destinations.include?("germania")
        progress["romanEnteredGermania"] = true
        progress["romanLegionsEnteredGermania"] = (Array(progress["romanLegionsEnteredGermania"]) + [@unit_id]).uniq
      end
      if destinations.any? { |area_key| Area.find_by(key: area_key)&.region == "britannia" }
        progress["romanEnteredBritannia"] = true
        progress["romanLegionsEnteredBritannia"] = (Array(progress["romanLegionsEnteredBritannia"]) + [@unit_id]).uniq
      end
    end

    def record_unit_movement!(plan)
      movement["crossings"] ||= {}
      movement_units[@unit_id] ||= { "origin" => @from, "steps" => 0, "stopped" => false }
      moved = movement_units[@unit_id]
      moved["path"] ||= []

      plan.fetch("steps").each do |from, to, border|
        capacity = border.capacity
        moved["path"] << { "from" => from, "to" => to, "border" => border.kind }
        movement["crossings"]["#{from}->#{to}"] = movement["crossings"].fetch("#{from}->#{to}", 0).to_i + 1 if capacity
      end
      moved["entry"] = plan["entry"] || plan.fetch("steps").last.first
      if plan["naval"]
        moved["naval"] = true
        movement["navalDepartures"] ||= {}
        movement["navalDepartures"][@from] = movement["navalDepartures"].fetch(@from, 0).to_i + 1
      end

      if plan["force"]
        moved["force"] = true
        moved["steps"] = 2
        moved["stopped"] = true
        @state["supply"] = supply - 1
        return
      end

      moved["steps"] = moved["steps"].to_i + 1
      moved["force"] = true if moved["steps"] >= 2 && !moved["naval"]
      if retreat_movement?
        moved["stopped"] = true
        return
      end
      if off_map_departure?
        moved["stopped"] = true
        return
      end

      if !roman_legion? || border_stops?(plan.fetch("steps").first.third) || area_has_stopper?(@target, @unit["owner"]) || moved["steps"] >= 2
        moved["stopped"] = true
      end
      @state["supply"] = supply - 1 if moved["steps"] == 2
    end

    def activate_neutral_units_in_target!
      record = neutral_attack_record
      if ariovistus_entering? && record && !record["resolved"]
        record["outcomes"] = GameRules::Ariovistus.new(state: @state, roll: method(:d6)).resolve!(
          area_id: @target,
          entering_units: [@unit],
          eligible_unit_ids: record.fetch("unitIds")
        )
        record["resolved"] = true
      end

      units.values.select { |other| other["location"] == @target && other["owner"] == "neutral" }.each do |other|
        other["owner"] = active_player == "roman" ? "barbarian" : "roman"
        log("#{other.fetch("name")} joins the #{player_name(other.fetch("owner"))} player as #{unit_name} enters #{area_name(@target)}.")
      end
    end

    def neutral_attack_record
      return unless active_player == "barbarian"

      records = movement["neutralAttacks"] ||= {}
      return records[@target] if records.key?(@target)

      neutral_ids = units.values.filter_map do |other|
        other.fetch("id") if other["location"] == @target && other["owner"] == "neutral" && other["type"] == "barbarian"
      end
      return if neutral_ids.empty?

      records[@target] = {
        "unitIds" => neutral_ids,
        "resolved" => false,
        "outcomes" => []
      }
    end

    def ariovistus_entering?
      @unit_id == "ariovistus" && @unit["owner"] == "barbarian"
    end

    def off_map_departure?
      @from == "roman_off_map"
    end

    def consume_off_map_activation!
      return unless off_map_departure?

      remaining = movement.fetch("remaining", 0).to_i
      raise InvalidMove, "No group activations remain to move #{unit_name} from the Roman Off-Map area." unless remaining.positive?

      movement["remaining"] = remaining - 1
      log("#{unit_name} uses one group activation to enter Transalpine Gaul from the Roman Off-Map area; #{movement["remaining"]} remaining.")
    end

    def d6
      @state["diceRolledThisTurn"] = true
      @state["undoStack"] = []
      queued = @rolls.shift
      return queued if queued&.between?(1, 6)

      rand(1..6)
    end

    def naval_invasion_cost_due?
      return false unless roman_legion? && area_has_stopper?(@target, @unit["owner"])

      !movement.fetch("navalLandings", {}).key?(naval_landing_key)
    end

    def charge_naval_invasion!(plan)
      return unless plan["naval"] && naval_invasion_cost_due?

      @state["supply"] = supply - 1
      movement["navalLandings"] ||= {}
      movement["navalLandings"][naval_landing_key] = true
      log("Roman naval invasion from #{area_name(@from)} to #{area_name(@target)} costs 1 supply.")
    end

    def naval_landing_key
      @from
    end

    def persist!
      @session.update!(data: @state)
      @session.sync_from_data!
      @state
    end

    def border(from, to)
      Border.includes(:to_area).find_by(from_area: Area.find_by(key: from), to_area: Area.find_by(key: to))
    end

    def from_area
      @from_area ||= Area.find_by!(key: @from)
    end

    def target_area
      @target_area ||= Area.find_by(key: @target)
    end

    def legal_area_for_unit?
      return @unit["type"] == "roman" if @target == "roman_off_map"
      return @unit["type"].in?(["roman", "german"]) if @target == "germania"

      true
    end

    def border_stops?(border)
      border.kind.in?(["minor_river", "naval"])
    end

    def area_has_stopper?(area_key, owner)
      units.values.any? do |other|
        other["location"] == area_key && (enemy?(other["owner"], owner) || other["owner"] == "neutral")
      end
    end

    def enemy?(left, right)
      left != "neutral" && right != "neutral" && left != right
    end

    def roman_legion?
      @unit["owner"] == "roman" && @unit["type"] == "roman"
    end

    def movement_area_activated?(area_key)
      movement.fetch("areas", []).include?(area_key)
    end

    def movement_origin
      movement_units.dig(@unit_id, "origin") || @from
    end

    def movement_units
      movement["units"] ||= {}
    end

    def movement
      @state["movement"]
    end

    def retreat_movement?
      movement&.fetch("retreat", false)
    end

    def active_player
      @state.fetch("active")
    end

    def supply
      @state.fetch("supply").to_i
    end

    def units
      @state.fetch("units")
    end

    def unit(id)
      units.fetch(id)
    rescue KeyError
      raise InvalidMove, "Unknown unit #{id}."
    end

    def unit_name
      @unit.fetch("name")
    end

    def area_name(key)
      Area.find_by(key: key)&.name || key
    end

    def offboard?(key)
      key.in?(["offboard", "eliminated"])
    end

    def log(message)
      @state["log"] ||= []
      @state["log"].unshift(message)
      @state["log"] = @state["log"].first(80)
      GameRules::PostGameReport.record!(@state, message)
    end

    def player_name(player)
      player == "roman" ? "Roman" : "Barbarian"
    end
  end
end
