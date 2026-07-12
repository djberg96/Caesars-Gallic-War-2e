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

      harvest = roll_harvest
      apply_harvest!(harvest)
      reset_units!
      controlled_tribes = score_controlled_tribes!
      @state["turn"] = [@state.fetch("turn", 0).to_i + 1, YEARS - 1].min
      log("End turn complete. Harvest roll #{harvest}. Roman scores #{controlled_tribes} tribal VP.")

      GameRules::Deal.new(session: @session, state: @state).deal!
    end

    private

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

        units.values.any? do |unit|
          unit["location"] == area.key && unit["owner"] == "roman" && unit["type"] != "roman"
        end
      end
      @state["vp"] = @state.fetch("vp", 0).to_i + controlled
      controlled
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
