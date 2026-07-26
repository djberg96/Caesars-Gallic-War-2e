module GameRules
  class EndTurn
    class InvalidAction < StandardError; end

    YEARS = 8

    END_TURN_PHASES = %w[romanWintering romanReplacements romanReinforcements].freeze
    INITIAL_FORCE_POOL = %w[legion_i legion_xiii legion_xiv legion_xv].freeze
    MASSIVE_REVOLT_REINFORCEMENTS = %w[legion_v legion_vi].freeze

    def initialize(session:, state:, harvest_roll: nil, wintering_unit_ids: nil, replacement_steps: nil, reinforcement_builds: nil)
      @session = session
      @state = state.deep_dup
      @harvest_roll = harvest_roll&.to_i
      @wintering_submitted = !wintering_unit_ids.nil?
      @wintering_unit_ids = Array(wintering_unit_ids).map(&:to_s).uniq
      @replacements_submitted = !replacement_steps.nil?
      @replacement_steps = normalize_numeric_choices(replacement_steps)
      @reinforcements_submitted = !reinforcement_builds.nil?
      @reinforcement_builds = normalize_numeric_choices(reinforcement_builds)
    end

    def end_turn!
      raise InvalidAction, "The campaign is already complete." if @state["gameOver"].present?
      return resume_end_turn! if end_turn_in_progress?

      raise InvalidAction, "Finish the current movement action before ending the turn." if @state["movement"].present?
      raise InvalidAction, "Finish the current battle before ending the turn." if @state["battle"].present?
      raise InvalidAction, remaining_cards_message if remaining_cards.positive?

      begin_end_turn!
      return complete_wintering!(@wintering_unit_ids) if @wintering_submitted || wintering_legions.empty?

      persist!
    end

    private

    def begin_end_turn!
      harvest = roll_harvest
      garrison_limit = harvest == 1 ? 1 : harvest == 6 ? 3 : 2
      apply_harvest!(harvest)
      log("Check Harvest: rolled #{harvest}. Garrison limit #{garrison_limit}; Roman supply is #{@state.fetch("supply")}.")

      replacements = apply_german_and_gallic_replacements!
      log(replacements.empty? ? "German and Gallic Replacements: no eligible units." : "German and Gallic Replacements: #{replacements.join(", ")} gain 1 strength.")

      returned = return_eliminated_gallic_units!
      log(returned.empty? ? "Eliminated Gallic Units: none return." : "Eliminated Gallic Units: #{returned.join("; ")}.")
      mark_newly_eliminated_legions!

      @state["phase"] = "End of Turn"
      @state["endTurn"] = {
        "phase" => "romanWintering",
        "harvestRoll" => harvest,
        "garrisonLimit" => garrison_limit,
        "eligibleLegions" => wintering_legions.map { |unit| unit.fetch("id") }
      }
    end

    def resume_end_turn!
      case @state.dig("endTurn", "phase")
      when "romanWintering"
        raise InvalidAction, "Choose which Roman legions will remain in winter quarters." unless @wintering_submitted

        complete_wintering!(@wintering_unit_ids)
      when "romanReplacements"
        raise InvalidAction, "Choose Roman replacement steps or continue without replacements." unless @replacements_submitted

        apply_roman_replacements!(@replacement_steps)
        apply_roman_supply_production!
        begin_roman_reinforcements!
      when "romanReinforcements"
        raise InvalidAction, "Choose Roman reinforcements or continue without building a legion." unless @reinforcements_submitted

        apply_roman_reinforcements!(@reinforcement_builds)
        complete_end_turn!
      else
        raise InvalidAction, "The end-of-turn phase is not valid."
      end
    end

    def complete_wintering!(wintering_ids)
      validate_wintering_choices!(wintering_ids)
      roman_allies = gallic_units("roman").map { |unit| unit.fetch("id") }
      barbarian_allies = gallic_units("barbarian").map { |unit| unit.fetch("id") }
      return_roman_legions!(wintering_ids)
      return_roman_allies!(roman_allies)
      return_barbarian_allies!(barbarian_allies)
      return_german_units!
      apply_winter_supply!(wintering_ids)

      return complete_end_turn! if final_turn?

      begin_roman_replacements!
    end

    def begin_roman_replacements!
      options = roman_replacement_options
      if options.empty?
        log("Roman Replacements and Reorganization: no damaged legions are eligible.")
        apply_roman_supply_production!
        return begin_roman_reinforcements!
      end

      @state["endTurn"] = @state.fetch("endTurn", {}).merge(
        "phase" => "romanReplacements",
        "replacementOptions" => options
      )
      persist!
    end

    def begin_roman_reinforcements!
      returned = return_eliminated_roman_legions!
      log(returned.empty? ? "Eliminated Roman Legions: none return this year." : "Eliminated Roman Legions Return: #{returned.join(", ")} return at full strength in the Roman Off-Map area.")
      refresh_force_pool!
      options = roman_reinforcement_options
      if options.empty?
        log("Roman Reinforcements: no unbuilt legions are available.")
        return complete_end_turn!
      end

      @state["endTurn"] = @state.fetch("endTurn", {}).merge(
        "phase" => "romanReinforcements",
        "reinforcementOptions" => options,
        "reinforcementLimit" => reinforcement_limit
      )
      persist!
    end

    def complete_end_turn!

      controlled_tribes = score_controlled_tribes!
      objectives = GameRules::YearlyObjectives.new(state: @state).score!
      log_objectives!(objectives) if objectives

      campaign_finished = final_turn?
      @state["phase"] = "Card Phase"
      @state["endTurn"] = nil
      objective_summary = objectives ? " Yearly Objectives: #{objectives.fetch("vp").positive? ? "+" : ""}#{objectives.fetch("vp")} VP." : ""
      log("End turn complete. Roman scores #{controlled_tribes} tribal VP.#{objective_summary}")

      return complete_campaign! if campaign_finished

      @state["turn"] = @state.fetch("turn", 0).to_i + 1
      @state["turnAnnouncementPending"] = true
      GameRules::Deal.new(session: @session, state: @state).deal!
    end

    def final_turn?
      @state.fetch("turn", 0).to_i >= YEARS - 1
    end

    def complete_campaign!
      vp = @state.fetch("vp", 0).to_i
      result, winner = if vp >= 110
        ["Massive Roman Victory", "roman"]
      elsif vp >= 100
        ["Major Roman Victory", "roman"]
      elsif vp >= 90
        ["Minor Roman Victory", "roman"]
      else
        ["Barbarian Victory", "barbarian"]
      end

      @state["phase"] = "Game Over"
      @state["gameOver"] = {
        "winner" => winner,
        "result" => result,
        "vp" => vp
      }
      @state["selectedCard"] = nil
      @state["currentAction"] = nil
      @state["botDeck"] = []
      log("Campaign complete: #{result} with #{vp} Roman VP.")
      persist!
    end

    def end_turn_in_progress?
      END_TURN_PHASES.include?(@state.dig("endTurn", "phase"))
    end

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

    def apply_german_and_gallic_replacements!
      units.values.filter_map do |unit|
        next unless unit["type"].in?(["barbarian", "german"])
        next if unit["location"].in?(["eliminated", "offboard"])
        home = unit["type"] == "barbarian" ? gallic_home(unit) : unit.fetch("home")
        next unless unit["location"] == home
        next unless unit.fetch("step", 0).to_i.positive?

        unit["step"] = unit.fetch("step").to_i - 1
        unit.fetch("name")
      end
    end

    def return_eliminated_gallic_units!
      units.values.filter_map do |unit|
        next unless unit["type"] == "barbarian" && unit["location"] == "eliminated"

        if unit["id"] == "helvetii"
          unit["location"] = "offboard"
          return_nantuates!
          next "Helvetii are permanently removed; Nantuates return at full strength"
        end

        home = gallic_home(unit)
        owner = occupying_owner(home, excluding: unit.fetch("id"))
        unit["location"] = home
        if owner
          unit["owner"] = owner
          unit["step"] = weakest_step(unit)
          "#{unit.fetch("name")} return under #{player_name(owner)} control at strength 1"
        else
          unit["owner"] = "neutral"
          unit["step"] = 0
          "#{unit.fetch("name")} return neutral at full strength"
        end
      end
    end

    def return_nantuates!
      nantuates = units["nantuates"]
      return unless nantuates

      owner = occupying_owner("helvetii", excluding: "nantuates")
      nantuates["home"] = "helvetii"
      nantuates["location"] = "helvetii"
      nantuates["owner"] = owner || "neutral"
      nantuates["step"] = 0
    end

    def wintering_legions
      eligible_ids = @state.dig("endTurn", "eligibleLegions")
      candidates = units.values.select do |unit|
        unit["type"] == "roman" &&
          unit["owner"] == "roman" &&
          !unit["location"].in?(["transalpine_gaul", "roman_off_map", "offboard", "eliminated", "germania"])
      end
      return candidates unless eligible_ids

      candidates.select { |unit| eligible_ids.include?(unit.fetch("id")) }
    end

    def validate_wintering_choices!(wintering_ids)
      eligible = wintering_legions.index_by { |unit| unit.fetch("id") }
      unknown = wintering_ids - eligible.keys
      raise InvalidAction, "Only eligible Roman legions may be selected for winter quarters." if unknown.any?

      if @state["caesarWintered"] && wintering_ids.include?("legion_x")
        raise InvalidAction, "Caesar wintered outside Transalpine Gaul last year and must return home this year."
      end

      selected = wintering_ids.filter_map { |id| eligible[id] }
      raise InvalidAction, "Roman legions may not winter in Germania." if selected.any? { |unit| unit["location"] == "germania" }

      limit = @state.dig("endTurn", "garrisonLimit").to_i
      selected.reject { |unit| unit["id"] == "legion_x" }.group_by { |unit| unit.fetch("location") }.each do |area_id, legions|
        next if legions.length <= limit

        raise InvalidAction, "Only #{limit} legion#{limit == 1 ? "" : "s"} may winter in #{area_name(area_id)} after this harvest."
      end
    end

    def return_roman_legions!(wintering_ids)
      returning = units.values.select do |unit|
        unit["type"] == "roman" &&
          !unit["location"].in?(["roman_off_map", "offboard", "eliminated", "transalpine_gaul"]) &&
          !wintering_ids.include?(unit.fetch("id"))
      end
      returning.each { |unit| unit["location"] = "transalpine_gaul" }
      @state["caesarWintered"] = wintering_ids.include?("legion_x")

      staying = wintering_ids.map { |id| units.fetch(id).fetch("name") }
      log(staying.empty? ? "Roman Legions Return Home: all legions return to Transalpine Gaul." : "Roman Winter Quarters: #{staying.join(", ")} remain in Gaul; all other legions return to Transalpine Gaul.")
    end

    def return_roman_allies!(unit_ids)
      returned = unit_ids.map do |unit_id|
        unit = units.fetch(unit_id)
        home = gallic_home(unit)
        unit["owner"] = "barbarian" if occupying_owner(home, excluding: unit.fetch("id")) == "barbarian"
        unit["location"] = home
        "#{unit.fetch("name")} (#{player_name(unit.fetch("owner"))})"
      end
      log(returned.empty? ? "Roman Gallic Allies: none return." : "Roman Gallic Allies Return Home: #{returned.join(", ")}.")
    end

    def return_barbarian_allies!(unit_ids)
      returned = unit_ids.map do |unit_id|
        unit = units.fetch(unit_id)
        home = gallic_home(unit)
        unit["owner"] = "roman" if occupying_owner(home, excluding: unit.fetch("id")) == "roman"
        unit["location"] = home
        "#{unit.fetch("name")} (#{player_name(unit.fetch("owner"))})"
      end
      log(returned.empty? ? "Barbarian Gallic Allies: none return." : "Barbarian Gallic Allies Return Home: #{returned.join(", ")}.")
    end

    def gallic_units(owner)
      units.values.select do |unit|
        unit["type"] == "barbarian" &&
          unit["owner"] == owner &&
          !unit["location"].in?(["offboard", "eliminated"])
      end
    end

    def return_german_units!
      returned = units.values.filter_map do |unit|
        next unless unit["type"] == "german"

        unit["step"] = weakest_step(unit) if unit["location"] == "eliminated"
        unit["location"] = "germania"
        unit["owner"] = "barbarian"
        unit.fetch("name")
      end
      log(returned.empty? ? "German Units: none return." : "German Units Return Home: #{returned.join(", ")} return to Germania.")
    end

    def apply_winter_supply!(wintering_ids)
      supplied = []
      attrition = []
      wintering_ids.each do |id|
        unit = units.fetch(id)
        next if id == "legion_x"

        if @state.fetch("supply", 0).to_i.positive?
          @state["supply"] = @state.fetch("supply").to_i - 1
          supplied << unit.fetch("name")
        else
          unit["step"] = unit.fetch("step", 0).to_i + 1
          if current_strength(unit).positive?
            attrition << "#{unit.fetch("name")} lose 1 strength"
          else
            unit["location"] = "eliminated"
            unit["eliminatedTurn"] = @state.fetch("turn", 0).to_i
            @state["vp"] = [@state.fetch("vp", 0).to_i - 5, 0].max
            attrition << "#{unit.fetch("name")} are eliminated"
          end
        end
      end
      detail = []
      detail << "supplied #{supplied.join(", ")}" if supplied.any?
      detail << attrition.join(", ") if attrition.any?
      log(detail.empty? ? "Supply and Attrition: no winter-quarter supply required." : "Supply and Attrition: #{detail.join("; ")}.")
    end

    def roman_replacement_options
      units.values.filter_map do |unit|
        next unless unit["type"] == "roman" && unit["owner"] == "roman"
        next if unit["location"].in?(["offboard", "eliminated"])

        strength = current_strength(unit)
        maximum = unit_strengths(unit).max.to_i
        missing_steps = unit.fetch("step", 0).to_i
        next unless strength.positive? && missing_steps.positive?

        home_area = unit["location"].in?(["transalpine_gaul", "roman_off_map"])
        {
          "id" => unit.fetch("id"),
          "name" => unit.fetch("name"),
          "location" => unit.fetch("location"),
          "locationName" => area_name(unit.fetch("location")),
          "currentStrength" => strength,
          "maximumStrength" => maximum,
          "maximumSteps" => home_area ? missing_steps : 1
        }
      end.sort_by { |option| option.fetch("name") }
    end

    def apply_roman_replacements!(choices)
      options = roman_replacement_options.index_by { |option| option.fetch("id") }
      validate_known_choices!(choices, options, "replacement")
      total = choices.sum do |unit_id, steps|
        next 0 if steps.zero?

        maximum = options.fetch(unit_id).fetch("maximumSteps")
        raise InvalidAction, "#{options.fetch(unit_id).fetch("name")} may receive at most #{maximum} replacement step#{maximum == 1 ? "" : "s"}." if steps > maximum

        steps
      end
      raise InvalidAction, "Roman replacements cost #{total} supply, but only #{@state.fetch("supply", 0)} is available." if total > @state.fetch("supply", 0).to_i

      replaced = choices.filter_map do |unit_id, steps|
        next if steps.zero?

        unit = units.fetch(unit_id)
        unit["step"] = unit.fetch("step", 0).to_i - steps
        "#{unit.fetch("name")} +#{steps}"
      end
      @state["supply"] = @state.fetch("supply", 0).to_i - total
      log(replaced.empty? ? "Roman Replacements and Reorganization: no supply spent." : "Roman Replacements and Reorganization: #{replaced.join(", ")} strength; #{total} supply spent.")
    end

    def apply_roman_supply_production!
      sources = [["Transalpine Gaul", 2]]
      Area.where.not(fort_name: nil).order(:key).each do |area|
        next if area.key == "transalpine_gaul"
        next unless roman_controls_area?(area)

        sources << [area.fort_name.to_s.titleize, area.key == "bituriges" ? 2 : 1]
      end

      produced = sources.sum(&:last)
      before = @state.fetch("supply", 0).to_i
      @state["supply"] = [before + produced, 19].min
      gained = @state.fetch("supply") - before
      source_text = sources.map { |name, amount| "#{name} +#{amount}" }.join(", ")
      cap_text = gained < produced ? " (limited by the 19-supply maximum)" : ""
      log("Roman Supply Production: #{source_text}; supply #{before} to #{@state.fetch("supply")}#{cap_text}.")
    end

    def roman_controls_area?(area)
      tribe_ids = (area.tribes + [area.alternate_tribe]).compact
      tribe_ids.any? do |unit_id|
        unit = units[unit_id]
        unit && unit["owner"] == "roman" && !unit["location"].in?(["offboard", "eliminated", nil]) && current_strength(unit).positive?
      end
    end

    def mark_newly_eliminated_legions!
      units.values.each do |unit|
        next unless unit["type"] == "roman" && unit["location"] == "eliminated"

        unit["eliminatedTurn"] ||= @state.fetch("turn", 0).to_i
      end
    end

    def return_eliminated_roman_legions!
      turn = @state.fetch("turn", 0).to_i
      units.values.filter_map do |unit|
        next unless unit["type"] == "roman" && unit["location"] == "eliminated"
        next unless unit["eliminatedTurn"].to_i < turn

        unit["location"] = "roman_off_map"
        unit["owner"] = "roman"
        unit["step"] = 0
        unit.delete("eliminatedTurn")
        unit.fetch("name")
      end
    end

    def refresh_force_pool!
      @state["romanForcePool"] ||= INITIAL_FORCE_POOL.select do |unit_id|
        units[unit_id]&.fetch("location", nil) == "offboard"
      end
      return unless massive_revolt_reinforcements_unlocked?

      MASSIVE_REVOLT_REINFORCEMENTS.each do |unit_id|
        next unless units[unit_id]&.fetch("location", nil) == "offboard"

        @state["romanForcePool"] << unit_id unless @state["romanForcePool"].include?(unit_id)
      end
    end

    def roman_reinforcement_options
      Array(@state["romanForcePool"]).filter_map do |unit_id|
        unit = units[unit_id]
        next unless unit && unit["location"] == "offboard"

        {
          "id" => unit.fetch("id"),
          "name" => unit.fetch("name"),
          "maximumStrength" => [unit_strengths(unit).max.to_i, 4].min
        }
      end.sort_by { |option| option.fetch("name") }
    end

    def reinforcement_limit
      massive_revolt_reinforcements_unlocked? ? 2 : 1
    end

    def massive_revolt_reinforcements_unlocked?
      return false unless @state["massiveRevoltPlayed"]

      units.dig("vercingetorix", "location").present? && units.dig("vercingetorix", "location") != "offboard"
    end

    def apply_roman_reinforcements!(choices)
      options = roman_reinforcement_options.index_by { |option| option.fetch("id") }
      validate_known_choices!(choices, options, "reinforcement")
      builds = choices.select { |_unit_id, strength| strength.positive? }
      if builds.length > reinforcement_limit
        raise InvalidAction, "Only #{reinforcement_limit} new legion#{reinforcement_limit == 1 ? "" : "s"} may be built this year."
      end

      total = builds.sum do |unit_id, strength|
        maximum = options.fetch(unit_id).fetch("maximumStrength")
        raise InvalidAction, "#{options.fetch(unit_id).fetch("name")} must be built at strength 1 through #{maximum}." unless strength.between?(1, maximum)

        strength
      end
      raise InvalidAction, "Roman reinforcements cost #{total} supply, but only #{@state.fetch("supply", 0)} is available." if total > @state.fetch("supply", 0).to_i

      built = builds.map do |unit_id, strength|
        unit = units.fetch(unit_id)
        step = unit_strengths(unit).index(strength)
        raise InvalidAction, "#{unit.fetch("name")} cannot be built at strength #{strength}." unless step

        unit["location"] = "roman_off_map"
        unit["owner"] = "roman"
        unit["step"] = step
        @state["romanForcePool"].delete(unit_id)
        "#{unit.fetch("name")} at strength #{strength}"
      end
      @state["supply"] = @state.fetch("supply", 0).to_i - total
      log(built.empty? ? "Roman Reinforcements: no new legion built." : "Roman Reinforcements: #{built.join(", ")} placed in the Roman Off-Map area; #{total} supply spent.")
    end

    def validate_known_choices!(choices, options, kind)
      unknown = choices.select { |unit_id, value| value.positive? && !options.key?(unit_id) }.keys
      return if unknown.empty?

      raise InvalidAction, "Unknown Roman #{kind} choice: #{unknown.join(", ")}."
    end

    def normalize_numeric_choices(choices)
      raw = if choices.respond_to?(:to_unsafe_h)
        choices.to_unsafe_h
      elsif choices.respond_to?(:to_h)
        choices.to_h
      else
        {}
      end
      raw.to_h { |unit_id, value| [unit_id.to_s, [value.to_i, 0].max] }
    end

    def occupying_owner(area_id, excluding: nil)
      units.values.filter_map do |unit|
        next if unit["id"] == excluding
        next unless unit["location"] == area_id
        next unless unit["owner"].in?(["roman", "barbarian"])
        next unless current_strength(unit).positive?

        unit["owner"]
      end.uniq.first
    end

    def weakest_step(unit)
      [unit_strengths(unit).length - 1, 0].max
    end

    def current_strength(unit)
      unit_strengths(unit)[unit.fetch("step", 0).to_i].to_i
    end

    def unit_strengths(unit)
      Array(unit["strengths"]).presence || Array(UnitType.find_by(key: unit["id"])&.strengths).presence || [1]
    end

    def gallic_home(unit)
      unit["id"] == "nantuates" ? "helvetii" : unit.fetch("home")
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

    def player_name(player)
      player == "roman" ? "Roman" : "Barbarian"
    end

    def area_name(area_id)
      Area.find_by(key: area_id)&.name || area_id.to_s.titleize
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
  end
end
