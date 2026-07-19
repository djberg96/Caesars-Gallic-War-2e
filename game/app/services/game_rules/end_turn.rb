module GameRules
  class EndTurn
    class InvalidAction < StandardError; end

    YEARS = 8

    def initialize(session:, state:, harvest_roll: nil)
      @session = session
      @state = state.deep_dup
      @harvest_roll = harvest_roll&.to_i
    end

    def end_turn!
      raise InvalidAction, "Finish the current movement action before ending the turn." if @state["movement"].present?
      raise InvalidAction, "Finish the current battle before ending the turn." if @state["battle"].present?
      raise InvalidAction, remaining_cards_message if remaining_cards.positive?

      harvest = roll_harvest
      apply_harvest!(harvest)
      controlled_tribes = score_controlled_tribes!
      objectives = GameRules::YearlyObjectives.new(state: @state).score!
      log_objectives!(objectives) if objectives
      reset_units!
      @state["turn"] = [@state.fetch("turn", 0).to_i + 1, YEARS - 1].min
      objective_summary = objectives ? " Yearly Objectives: #{objectives.fetch("vp").positive? ? "+" : ""}#{objectives.fetch("vp")} VP." : ""
      log("End turn complete. Harvest roll #{harvest}. Roman scores #{controlled_tribes} tribal VP.#{objective_summary}")

      GameRules::Deal.new(session: @session, state: @state).deal!
    end

    private

    def remaining_cards
      hands = @state.fetch("hands", {})
      players = @state.fetch("mode", "hotseat") == "hotseat" ? %w[roman barbarian] : %w[roman]
      players.sum { |player| Array(hands[player]).length }
    end

    def remaining_cards_message
      "Play the remaining #{remaining_cards} card#{remaining_cards == 1 ? "" : "s"} before ending the turn."
    end

    def roll_harvest
      return @harvest_roll if @harvest_roll&.between?(1, 6)

      rand(1..6)
    end

    def apply_harvest!(harvest)
      @state["supply"] = [@state.fetch("supply", 0).to_i - 2, 0].max if harvest == 1
      @state["supply"] = [@state.fetch("supply", 0).to_i + 2, 19].min if harvest == 6
    end

    def reset_units!
      units.each_value do |unit|
        if unit["location"] == "eliminated" && unit["type"] != "roman"
          unit["location"] = unit["home"] == "offboard" ? "offboard" : unit["home"]
          unit["owner"] = "neutral"
          unit["step"] = 0
        elsif unit["type"] == "roman" && !unit["location"].in?(["eliminated", "offboard"])
          unit["location"] = "transalpine_gaul"
        elsif unit["type"].in?(["barbarian", "leader"]) && unit["home"] != "offboard" && unit["location"] != "offboard"
          unit["location"] = unit["home"]
        elsif unit["type"] == "german" && unit["location"] != "eliminated"
          unit["location"] = "germania"
        end
      end
    end

    def score_controlled_tribes!
      controlled = Area.order(:key).count do |area|
        next false if area.region.blank? || area.region == "roman" || area.sea?

        tribe_ids = (area.tribes + [area.alternate_tribe]).compact
        tribe_ids.any? do |unit_id|
          unit = units[unit_id]
          unit && unit["owner"] == "roman" && !unit["location"].in?(["offboard", "eliminated", nil])
        end
      end
      @state["vp"] = @state.fetch("vp", 0).to_i + controlled
      controlled
    end

    def log_objectives!(result)
      result.fetch("objectives").reverse_each do |objective|
        value = objective.fetch("vp")
        log("Yearly objective #{value.positive? ? "+" : ""}#{value} VP: #{objective.fetch("text")}")
      end
      log("No Yearly Objectives scored for #{result.fetch("title")}.") if result.fetch("objectives").empty?
    end

    def units
      @state.fetch("units")
    end

    def log(message)
      @state["log"] ||= []
      @state["log"].unshift(message)
      @state["log"] = @state["log"].first(80)
    end
  end
end
