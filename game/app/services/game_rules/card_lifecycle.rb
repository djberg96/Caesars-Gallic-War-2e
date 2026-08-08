module GameRules
  module CardLifecycle
    MASSIVE_REVOLT_ID = "event_4_massive_revolt".freeze

    module_function

    def finish_play!(state, card)
      if removed_from_game?(state, card)
        state["removedCards"] ||= []
        state["removedCards"] << card unless card_in?(state["removedCards"], card)
        state["discard"] = Array(state["discard"]).reject { |discarded| same_card?(discarded, card) }
        :removed
      else
        state["discard"] ||= []
        state["discard"] << card unless card_in?(state["discard"], card)
        :discarded
      end
    end

    def available_cards(state, cards)
      removed_ids = Array(state["removedCards"]).filter_map { |card| card["id"] }
      removed_ids << MASSIVE_REVOLT_ID if massive_revolt_played?(state)
      cards.reject { |card| removed_ids.include?(card["id"]) }
    end

    def reconcile_removed_cards!(state, cards)
      return unless massive_revolt_played?(state)

      massive_revolt = cards.find { |card| card["id"] == MASSIVE_REVOLT_ID }
      finish_play!(state, massive_revolt) if massive_revolt
    end

    def removed_from_game?(state, card)
      card["id"] == MASSIVE_REVOLT_ID && massive_revolt_played?(state)
    end

    def massive_revolt_played?(state)
      ActiveModel::Type::Boolean.new.cast(state["massiveRevoltPlayed"])
    end

    def card_in?(cards, card)
      Array(cards).any? { |candidate| same_card?(candidate, card) }
    end

    def same_card?(left, right)
      left["id"] == right["id"]
    end
  end
end
