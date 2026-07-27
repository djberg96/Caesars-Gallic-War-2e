module GameRules
  class Ariovistus
    def initialize(state:, roll:)
      @state = state
      @roll = roll
    end

    def resolve!(area_id:, entering_units:, eligible_unit_ids: nil)
      return [] unless entering_units.any? { |unit| unit.fetch("id") == "ariovistus" }

      candidates = eligible_units(area_id, eligible_unit_ids)
      candidates.map do |unit|
        die = @roll.call
        subdued = die <= 2
        unit["owner"] = subdued ? "barbarian" : "roman"
        log(result_message(unit, die, subdued))
        {
          "unitId" => unit.fetch("id"),
          "roll" => die,
          "subdued" => subdued
        }
      end
    end

    private

    def eligible_units(area_id, eligible_unit_ids)
      ids = Array(eligible_unit_ids).presence
      @state.fetch("units").values.select do |unit|
        unit["location"] == area_id &&
          unit["type"] == "barbarian" &&
          (ids ? ids.include?(unit.fetch("id")) : unit["owner"] == "neutral")
      end
    end

    def result_message(unit, die, subdued)
      outcome = if subdued
        "#{unit.fetch("name")} joins the Barbarian attacking force"
      else
        "#{unit.fetch("name")} resists and joins the Roman defense"
      end
      "Ariovistus special ability: rolled #{die} for #{unit.fetch("name")}; #{outcome}."
    end

    def log(message)
      @state["log"] ||= []
      @state["log"].unshift(message)
      @state["log"] = @state["log"].first(80)
    end
  end
end
