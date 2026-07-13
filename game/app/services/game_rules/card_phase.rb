module GameRules
  class CardPhase
    class InvalidAction < StandardError; end

    def initialize(session:, state:)
      @session = session
      @state = state.deep_dup
    end

    def commit!(player:, card_id:)
      @player = player.to_s
      @card_id = card_id.to_s

      validate_hotseat!
      validate_player!
      raise InvalidAction, "Resolve the revealed cards before committing new cards." if @state["revealed"]

      card = hand.find { |candidate| candidate.fetch("id") == @card_id }
      raise InvalidAction, "Select a card from your hand before committing." unless card

      @state["committed"] ||= { "roman" => nil, "barbarian" => nil }
      @state["committed"][@player] = card
      @state["selectedCard"] = nil
      log("#{player_name(@player)} committed a card face down.")
      persist!
    end

    def reveal!
      validate_hotseat!
      committed = @state.fetch("committed", {})
      raise InvalidAction, "Both players must commit a card before reveal." unless committed["roman"] && committed["barbarian"]

      @state["revealed"] = true
      log("Cards revealed: Roman #{committed.fetch("roman").fetch("title")}; Barbarian #{committed.fetch("barbarian").fetch("title")}.")
      persist!
    end

    def discard!(player:)
      @player = player.to_s
      validate_player!

      played = action_card
      raise InvalidAction, "No card is ready to discard." unless played

      remove_from_hand(played.fetch("id"))
      @state["discard"] ||= []
      @state["discard"] << played
      @state["movement"] = nil
      @state["battle"] = nil
      @state["currentAction"] = nil
      @state["selectedCard"] = nil

      if @state["mode"] == "hotseat"
        @state["committed"] ||= { "roman" => nil, "barbarian" => nil }
        @state["committed"][@player] = nil
        @state["revealed"] = @state.fetch("committed").values.any?
      end

      persist!
    end

    private

    def validate_hotseat!
      raise InvalidAction, "Reveal and commit are only used in hotseat mode." unless @state["mode"] == "hotseat"
    end

    def validate_player!
      raise InvalidAction, "Unknown player #{@player}." unless @player.in?(["roman", "barbarian"])
    end

    def hand
      @state.fetch("hands").fetch(@player)
    end

    def action_card
      if @state["mode"] == "hotseat"
        @state["revealed"] ? @state.dig("committed", @player) : @state["selectedCard"]
      else
        @player == "roman" ? @state["selectedCard"] : nil
      end
    end

    def remove_from_hand(card_id)
      index = hand.index { |card| card.fetch("id") == card_id }
      hand.delete_at(index) if index
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
