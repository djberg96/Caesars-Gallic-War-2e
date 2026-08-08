module GameRules
  class Deal
    HAND_SIZE = 5

    def initialize(session:, state:)
      @session = session
      @state = state.deep_dup
    end

    def deal!
      all_cards = Card.includes(:area).order(:id).map(&:game_data).map(&:stringify_keys)
      GameRules::CardLifecycle.reconcile_removed_cards!(@state, all_cards)
      deck = GameRules::CardLifecycle.available_cards(@state, all_cards).shuffle
      @state["hands"] ||= {}
      @state["hands"]["roman"] = deck.shift(HAND_SIZE)

      if @state["mode"] == "hotseat"
        @state["hands"]["barbarian"] = deck.shift(HAND_SIZE)
        @state["botDeck"] = []
      else
        @state["hands"]["barbarian"] = []
        @state["botDeck"] = deck
      end

      @state["botNeutralActivations"] = 0
      @state["neutralActivationCards"] = { "roman" => [], "barbarian" => [] }
      @state["discard"] = []
      @state["selectedCard"] = nil
      @state["committed"] = { "roman" => nil, "barbarian" => nil }
      @state["revealed"] = false
      @state["movement"] = nil
      @state["battle"] = nil
      @state["currentAction"] = nil
      @state["undoStack"] = []
      @state["diceRolledThisTurn"] = false
      announce_scheduled_minor_leader!
      log(deal_message)

      @session.update!(data: @state)
      @session.sync_from_data!
      @state
    end

    private

    def announce_scheduled_minor_leader!
      placement = GameRules::MinorLeaders.new(state: @state).place_scheduled!
      return unless placement

      leader = placement.fetch("leader")
      area = placement.fetch("area")
      log("#{leader.fetch("name")} enters at the start of Turn #{@state.fetch("turn", 0).to_i + 1} in #{area.name}; all tribes there become Barbarian allies.")
    end

    def deal_message
      if @state["mode"] == "hotseat"
        "Dealt #{HAND_SIZE} cards to each player."
      else
        "Dealt #{HAND_SIZE} cards to the Roman player. The opponent uses the draw deck."
      end
    end

    def log(message)
      @state["log"] ||= []
      @state["log"].unshift(message)
      @state["log"] = @state["log"].first(80)
      GameRules::PostGameReport.record!(@state, message)
    end
  end
end
