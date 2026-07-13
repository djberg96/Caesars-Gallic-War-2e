module GameRules
  class Battle
    def initialize(session:, state:, rolls: nil)
      @session = session
      @state = state.deep_dup
      @rolls = Array(rolls).map(&:to_i)
    end

    def resolve!
      battle_areas = contested_areas
      if battle_areas.empty?
        log("No battles to resolve.")
        return persist!
      end

      battle_areas.each { |area| resolve_battle(area) }
      persist!
    end

    private

    def contested_areas
      Area.order(:key).select do |area|
        owners = area_units(area.key).map { |unit| unit["owner"] }.reject { |owner| owner == "neutral" }
        owners.include?("roman") && owners.include?("barbarian")
      end
    end

    def resolve_battle(area)
      max_rounds = area.key == "germania" ? 2 : 3
      log("Battle begins in #{area.name}.")

      (1..max_rounds).each do
        fighters = area_units(area.key).select { |unit| unit["owner"].in?(["roman", "barbarian"]) }
        break unless both_sides?(fighters)

        fighters.sort_by { |unit| initiative_value(unit) }.each do |unit|
          next if unit["location"] != area.key || current_strength(unit) <= 0

          enemies = area_units(area.key).select { |other| enemy?(other["owner"], unit["owner"]) }
          next if enemies.empty?

          rolls = Array.new(current_strength(unit)) { d6 }
          hits = rolls.count { |roll| roll <= unit.fetch("fire").to_i }
          apply_hits(enemies, hits) if hits.positive?
          log("#{unit.fetch("name")} fires #{rolls.join(", ")} for #{hits} hit#{hits == 1 ? "" : "s"}.")
        end
        eliminate_dead(area.key)
      end

      survivors = area_units(area.key).select { |unit| unit["owner"].in?(["roman", "barbarian"]) }
      if both_sides?(survivors)
        prepare_retreat_movement!(area)
        log("Battle in #{area.name} is unresolved after #{max_rounds} rounds. Move retreats manually.")
      elsif survivors.first
        log("#{player_name(survivors.first.fetch("owner"))} controls #{area.name} after battle.")
      end
    end

    def prepare_retreat_movement!(area)
      movement = @state["movement"] ||= {
        "player" => @state.fetch("active", "roman"),
        "cardId" => nil,
        "remaining" => 0,
        "areas" => [],
        "units" => {},
        "crossings" => {}
      }
      movement["retreat"] = true
      movement["remaining"] = 0
      movement["areas"] = (Array(movement["areas"]) + [area.key]).uniq
      movement["units"] = {}
      movement["crossings"] = {}
      @state["currentAction"] = "movement"
    end

    def d6
      @state["diceRolledThisTurn"] = true
      @state["undoStack"] = []
      @rolls.shift || rand(1..6)
    end

    def apply_hits(enemies, hits)
      hits.times do
        target = enemies
          .select { |unit| unit["location"] != "eliminated" }
          .max_by { |unit| current_strength(unit) }
        return unless target

        target["step"] = target.fetch("step", 0).to_i + 1
      end
    end

    def eliminate_dead(area_key)
      area_units(area_key).each do |unit|
        next if current_strength(unit).positive?

        unit["location"] = "eliminated"
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

    def current_strength(unit)
      strengths = unit["strengths"] || UnitType.find_by(key: unit["id"])&.strengths || []
      strengths[unit.fetch("step", 0).to_i].to_i
    end

    def initiative_value(unit)
      return 0 if unit["id"] == "legion_x"

      { "A" => 1, "B" => 2, "C" => 3, "D" => 4 }.fetch(unit["initiative"], 5)
    end

    def both_sides?(fighters)
      owners = fighters.map { |unit| unit["owner"] }
      owners.include?("roman") && owners.include?("barbarian")
    end

    def enemy?(left, right)
      left != "neutral" && right != "neutral" && left != right
    end

    def area_units(area_key)
      units.values.select { |unit| unit["location"] == area_key }
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
  end
end
