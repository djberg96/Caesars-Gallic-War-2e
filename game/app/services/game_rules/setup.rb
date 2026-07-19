module GameRules
  class Setup
    VARIABLE_AREAS = %w[atrebates carnutes esuvii menapi pictones atuatuci tarbelli tolosates].freeze
    BARBARIAN_STARTERS = %w[helvetii ariovistus german_marcomanni german_tencteri german_usipetes].freeze
    ROMAN_ALLIES = %w[volcae allobroges].freeze
    HAND_SIZE = 5

    def initialize(view_context:)
      @view_context = view_context
    end

    def state(mode: "hotseat", yearly_objectives: false)
      mode = mode.presence || "hotseat"
      deck = shuffled_deck
      yearly_objectives = ActiveModel::Type::Boolean.new.cast(yearly_objectives)

      state = {
        "turn" => 0,
        "phase" => "Card Phase",
        "active" => "roman",
        "supply" => 15,
        "vp" => 0,
        "units" => units,
        "selectedUnit" => nil,
        "selectedArea" => nil,
        "selectedCard" => nil,
        "committed" => { "roman" => nil, "barbarian" => nil },
        "revealed" => false,
        "mode" => mode,
        "options" => { "yearlyObjectives" => yearly_objectives },
        "yearlyObjectiveProgress" => {},
        "yearlyObjectiveHistory" => [],
        "botDeck" => [],
        "botNeutralActivations" => 0,
        "neutralActivationCards" => { "roman" => [], "barbarian" => [] },
        "currentAction" => nil,
        "movement" => nil,
        "battle" => nil,
        "dragArea" => nil,
        "undoStack" => [],
        "diceRolledThisTurn" => false,
        "gameSessionId" => nil,
        "hands" => { "roman" => deck.shift(HAND_SIZE), "barbarian" => [] },
        "discard" => [],
        "log" => []
      }

      deal_opponent_cards!(state, deck)
      state["log"] << "New game set up. Variable tribes were randomly selected."
      state["log"] << "Yearly Objectives optional rule enabled." if yearly_objectives
      state["log"] << deal_message(mode)
      state
    end

    private

    def units
      UnitType.order(:key).to_h do |unit_type|
        unit = unit_type.game_data(@view_context).stringify_keys
        unit["location"] = unit.fetch("home")
        unit["owner"] = unit.fetch("type") == "roman" ? "roman" : "neutral"
        unit["step"] = 0
        [unit.fetch("id"), unit]
      end.tap do |all_units|
        setup_variable_tribes!(all_units)
        setup_initial_owners!(all_units)
        setup_reduced_units!(all_units)
      end
    end

    def setup_variable_tribes!(all_units)
      VARIABLE_AREAS.each do |area_key|
        area = Area.find_by!(key: area_key)
        alternate = area.alternate_tribe
        next if alternate.blank?

        primary = area.tribes.first
        if rand < 0.5
          all_units.fetch(primary)["location"] = "offboard"
          all_units.fetch(alternate)["location"] = area_key
        else
          all_units.fetch(alternate)["location"] = "offboard"
        end
      end
    end

    def setup_initial_owners!(all_units)
      BARBARIAN_STARTERS.each { |unit_key| all_units.fetch(unit_key)["owner"] = "barbarian" }
      ROMAN_ALLIES.each { |unit_key| all_units.fetch(unit_key)["owner"] = "roman" }
    end

    def setup_reduced_units!(all_units)
      all_units.fetch("allobroges")["step"] = all_units.fetch("allobroges").fetch("strengths").length - 1
      all_units.fetch("legion_xi")["step"] = 1
      all_units.fetch("legion_xii")["step"] = 1
    end

    def shuffled_deck
      Card.includes(:area).order(:id).map(&:game_data).map(&:stringify_keys).shuffle
    end

    def deal_opponent_cards!(state, deck)
      if state.fetch("mode") == "hotseat"
        state.fetch("hands")["barbarian"] = deck.shift(HAND_SIZE)
      else
        state["botDeck"] = deck
      end
    end

    def deal_message(mode)
      if mode == "hotseat"
        "Dealt #{HAND_SIZE} cards to each player."
      else
        "Dealt #{HAND_SIZE} cards to the Roman player. The opponent uses the draw deck."
      end
    end
  end
end
