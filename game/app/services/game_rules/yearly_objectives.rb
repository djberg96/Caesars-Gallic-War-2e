module GameRules
  class YearlyObjectives
    CAMPAIGNS = [
      {
        "title" => "Ariovistus",
        "objectives" => [
          { "id" => "t1_roman_three", "text" => "Control Sequani, Allobroges, and Helvetii / Nantuates.", "vp" => 1 },
          { "id" => "t1_barbarian_sequani", "text" => "Barbarian controls Sequani.", "vp" => -1 },
          { "id" => "t1_helvetii_survives", "text" => "Helvetii has not been destroyed.", "vp" => -1 }
        ]
      },
      {
        "title" => "Belgic Campaign",
        "objectives" => [
          { "id" => "t2_roman_coast", "text" => "Control at least 3 territories adjacent to Oceanus Britannicus.", "vp" => 1 },
          { "id" => "t2_roman_atuatuci", "text" => "Control Remi / Atuatuci.", "vp" => 1 },
          { "id" => "t2_barbarian_coast", "text" => "Barbarian controls at least 3 territories adjacent to Oceanus Britannicus.", "vp" => -1 }
        ]
      },
      {
        "title" => "Galba, Crassus & the Veneti",
        "objectives" => [
          { "id" => "t3_helvetii_garrison", "text" => "Control Helvetii / Nantuates and garrison a legion there.", "vp" => 1 },
          { "id" => "t3_roman_armorica", "text" => "Control both Osismi and Veneti.", "vp" => 1 },
          { "id" => "t3_roman_aquitania", "text" => "Control at least one tribe in Aquitania.", "vp" => 1 },
          { "id" => "t3_barbarian_helvetii", "text" => "Barbarian controls Helvetii / Nantuates.", "vp" => -1 },
          { "id" => "t3_barbarian_aquitania", "text" => "Barbarian controls at least one tribe in Aquitania.", "vp" => -1 },
          { "id" => "t3_barbarian_osismi", "text" => "Barbarian controls Osismi.", "vp" => -1 },
          { "id" => "t3_barbarian_veneti", "text" => "Barbarian controls Veneti.", "vp" => -1 }
        ]
      },
      {
        "title" => "German Campaign & Britannia",
        "objectives" => [
          { "id" => "t4_german_winter", "text" => "A German unit winters in Menapi / Nervii or Atrebates / Morini.", "vp" => -2 },
          { "id" => "t4_germania_combat", "text" => "Cross into Germania with a legion and fight at least one combat round.", "vp" => 1 },
          { "id" => "t4_britannia_combat", "text" => "Cross into Britannia with a legion and fight at least one combat round.", "vp" => 1 },
          { "id" => "t4_roman_britannia", "text" => "Control Britannia.", "vp" => 1 }
        ]
      },
      {
        "title" => "Dumnorix & the British Campaign",
        "objectives" => [
          { "id" => "t5_britannia_expedition", "text" => "Cross into Britannia with at least 2 legions and fight a combat round.", "vp" => 1 },
          { "id" => "t5_dumnorix_killed", "text" => "Kill Dumnorix.", "vp" => 2 },
          { "id" => "t5_winter_quarters", "text" => "Winter at least one legion in at least 4 different territories.", "vp" => 1 },
          { "id" => "t5_barbarian_britannia", "text" => "Barbarian controls Britannia.", "vp" => -1 },
          { "id" => "t5_dumnorix_in_play", "text" => "Dumnorix remains in play.", "vp" => -2 }
        ]
      },
      {
        "title" => "Treveri, Ambiorix & Germania",
        "objectives" => [
          { "id" => "t6_roman_treveri", "text" => "Control Treveri / Eburones.", "vp" => 1 },
          { "id" => "t6_roman_atuatuci", "text" => "Control Remi / Atuatuci.", "vp" => 1 },
          { "id" => "t6_roman_menapi", "text" => "Control Menapi / Nervii.", "vp" => 1 },
          { "id" => "t6_ambiorix_killed", "text" => "Kill Ambiorix.", "vp" => 2 },
          { "id" => "t6_germania_crossing", "text" => "Cross into Germania with at least one legion.", "vp" => 1 },
          { "id" => "t6_barbarian_treveri", "text" => "Barbarian controls Treveri / Eburones.", "vp" => -1 },
          { "id" => "t6_barbarian_atuatuci", "text" => "Barbarian controls Remi / Atuatuci.", "vp" => -1 },
          { "id" => "t6_barbarian_menapi", "text" => "Barbarian controls Menapi / Nervii.", "vp" => -1 },
          { "id" => "t6_ambiorix_in_play", "text" => "Ambiorix remains in play.", "vp" => -2 }
        ]
      },
      {
        "title" => "Vercingetorix",
        "objectives" => [
          { "id" => "t7_vercingetorix_killed", "text" => "Kill Vercingetorix.", "vp" => 3 },
          { "id" => "t7_gallic_coalition", "text" => "Barbarian controls Vercingetorix and at least 4 Gallic tribes.", "vp" => -3 },
          { "id" => "t7_vercingetorix_absent", "text" => "Vercingetorix has not entered play.", "vp" => 1 }
        ]
      },
      {
        "title" => "Mopping Up",
        "objectives" => [
          { "id" => "t8_three_regions", "text" => "Eliminate or control a tribe in each of Belgica, Aquitania, and Celtae.", "vp" => 2 },
          { "id" => "t8_barbarian_majority", "text" => "Barbarian controls more tribes than Rome.", "vp" => -2 }
        ]
      }
    ].freeze

    COASTAL_AREAS = %w[andes atrebates belgae bellovaci esuvii osismi].freeze
    AREA_TRIBE_ALIASES = { "helvetii" => %w[nantuates] }.freeze
    TURN_SIX_AREAS = %w[treveri atuatuci menapi].freeze

    def initialize(state:)
      @state = state
    end

    def score!
      return nil unless enabled?

      campaign = CAMPAIGNS.fetch(turn)
      earned = campaign.fetch("objectives").select { |objective| objective_met?(objective.fetch("id")) }
      starting_vp = vp

      # The optional rule explicitly awards gains before applying losses.
      earned.sort_by { |objective| -objective.fetch("vp") }.each do |objective|
        @state["vp"] = [vp + objective.fetch("vp"), 0].max
      end

      result = {
        "turn" => turn,
        "title" => campaign.fetch("title"),
        "objectives" => earned,
        "vp" => vp - starting_vp
      }
      @state["yearlyObjectiveHistory"] ||= []
      @state["yearlyObjectiveHistory"] << result
      @state["yearlyObjectiveProgress"] = {}
      result
    end

    private

    def enabled?
      ActiveModel::Type::Boolean.new.cast(@state.dig("options", "yearlyObjectives"))
    end

    def turn
      @state.fetch("turn", 0).to_i.clamp(0, CAMPAIGNS.length - 1)
    end

    def vp
      @state.fetch("vp", 0).to_i
    end

    def objective_met?(id)
      case id
      when "t1_roman_three" then %w[sequani allobroges helvetii].all? { |area| controlled_by?(area, "roman") }
      when "t1_barbarian_sequani" then controlled_by?("sequani", "barbarian")
      when "t1_helvetii_survives" then unit_in_play?("helvetii")
      when "t2_roman_coast" then controlled_area_count(COASTAL_AREAS, "roman") >= 3
      when "t2_roman_atuatuci" then controlled_by?("atuatuci", "roman")
      when "t2_barbarian_coast" then controlled_area_count(COASTAL_AREAS, "barbarian") >= 3
      when "t3_helvetii_garrison" then controlled_by?("helvetii", "roman") && roman_legion_in?("helvetii")
      when "t3_roman_armorica" then %w[osismi veneti].all? { |area| controlled_by?(area, "roman") }
      when "t3_roman_aquitania" then controls_region?("roman", "aquitania")
      when "t3_barbarian_helvetii" then controlled_by?("helvetii", "barbarian")
      when "t3_barbarian_aquitania" then controls_region?("barbarian", "aquitania")
      when "t3_barbarian_osismi" then controlled_by?("osismi", "barbarian")
      when "t3_barbarian_veneti" then controlled_by?("veneti", "barbarian")
      when "t4_german_winter" then german_unit_in_any?(%w[menapi atrebates])
      when "t4_germania_combat" then progress?("romanEnteredGermania") && progress?("romanFoughtInGermania")
      when "t4_britannia_combat" then progress?("romanEnteredBritannia") && progress?("romanFoughtInBritannia")
      when "t4_roman_britannia" then controlled_by?("belgae", "roman")
      when "t5_britannia_expedition" then progress_ids("romanLegionsFoughtInBritannia").length >= 2
      when "t5_dumnorix_killed" then unit_eliminated?("dumnorix")
      when "t5_winter_quarters" then roman_winter_territories >= 4
      when "t5_barbarian_britannia" then controlled_by?("belgae", "barbarian")
      when "t5_dumnorix_in_play" then unit_in_play?("dumnorix")
      when "t6_roman_treveri" then controlled_by?("treveri", "roman")
      when "t6_roman_atuatuci" then controlled_by?("atuatuci", "roman")
      when "t6_roman_menapi" then controlled_by?("menapi", "roman")
      when "t6_ambiorix_killed" then unit_eliminated?("ambiorix")
      when "t6_germania_crossing" then progress?("romanEnteredGermania")
      when "t6_barbarian_treveri" then controlled_by?("treveri", "barbarian")
      when "t6_barbarian_atuatuci" then controlled_by?("atuatuci", "barbarian")
      when "t6_barbarian_menapi" then controlled_by?("menapi", "barbarian")
      when "t6_ambiorix_in_play" then unit_in_play?("ambiorix")
      when "t7_vercingetorix_killed" then unit_eliminated?("vercingetorix")
      when "t7_gallic_coalition" then unit_controlled_in_play?("vercingetorix", "barbarian") && controlled_tribe_count("barbarian", gallic_only: true) >= 4
      when "t7_vercingetorix_absent" then !unit_in_play?("vercingetorix") && !unit_eliminated?("vercingetorix")
      when "t8_three_regions" then %w[belgica aquitania celtae].all? { |region| roman_controls_or_eliminated_in_region?(region) }
      when "t8_barbarian_majority" then controlled_tribe_count("barbarian") > controlled_tribe_count("roman")
      else false
      end
    end

    def controlled_by?(area_key, owner)
      tribe_ids(area_key).any? { |id| unit_controlled_in_play?(id, owner) }
    end

    def controlled_area_count(area_keys, owner)
      area_keys.count { |area_key| controlled_by?(area_key, owner) }
    end

    def controls_region?(owner, region)
      region_areas(region).any? { |area| controlled_by?(area.key, owner) }
    end

    def roman_controls_or_eliminated_in_region?(region)
      region_areas(region).any? do |area|
        tribe_ids(area.key).any? do |id|
          unit_controlled_in_play?(id, "roman") || unit_eliminated?(id)
        end
      end
    end

    def region_areas(region)
      regions = region == "belgica" ? %w[belgica belgae] : [region]
      Area.where(region: regions)
    end

    def tribe_ids(area_key)
      area = Area.find_by(key: area_key)
      return [] unless area

      (area.tribes + [area.alternate_tribe] + AREA_TRIBE_ALIASES.fetch(area_key, [])).compact.select { |id| units.key?(id) }
    end

    def controlled_tribe_count(owner, gallic_only: false)
      units.values.count do |unit|
        next false unless unit["type"] == "barbarian" && unit["owner"] == owner
        next false unless on_map?(unit)
        next true unless gallic_only

        area = Area.find_by(key: unit["home"])
        area && area.region != "britannia"
      end
    end

    def roman_legion_in?(area_key)
      units.values.any? do |unit|
        unit["type"] == "roman" && unit["owner"] == "roman" && unit["location"] == area_key
      end
    end

    def roman_winter_territories
      units.values.filter_map do |unit|
        next unless unit["type"] == "roman" && unit["owner"] == "roman"

        area = Area.find_by(key: unit["location"])
        area.key if area && area.region.present? && area.region != "roman"
      end.uniq.length
    end

    def german_unit_in_any?(area_keys)
      units.values.any? { |unit| unit["type"] == "german" && unit["location"].in?(area_keys) && on_map?(unit) }
    end

    def unit_controlled_in_play?(id, owner)
      unit = units[id]
      unit && unit["owner"] == owner && on_map?(unit)
    end

    def unit_in_play?(id)
      unit = units[id]
      unit && on_map?(unit)
    end

    def unit_eliminated?(id)
      units.dig(id, "location") == "eliminated"
    end

    def on_map?(unit)
      !unit["location"].in?(["offboard", "eliminated", nil])
    end

    def progress?(key)
      ActiveModel::Type::Boolean.new.cast(@state.dig("yearlyObjectiveProgress", key))
    end

    def progress_ids(key)
      Array(@state.dig("yearlyObjectiveProgress", key)).uniq
    end

    def units
      @state.fetch("units")
    end
  end
end
