module GameRules
  class ActionPhase
    class InvalidAction < StandardError; end

    def initialize(session:, state:)
      @session = session
      @state = state.deep_dup
    end

    def start_movement!
      raise InvalidAction, "End the current movement action before choosing another card action." if @state["movement"].present?

      card = action_card
      raise InvalidAction, card_prompt unless card

      @state["currentAction"] = "movement"
      @state["movement"] = {
        "player" => active_player,
        "cardId" => card.fetch("id"),
        "remaining" => card.fetch("ap").to_i,
        "areas" => [],
        "units" => {},
        "crossings" => {}
      }
      log("#{player_name(active_player)} is using #{card.fetch("title")} for movement: activate up to #{card.fetch("ap")} group#{card.fetch("ap").to_i == 1 ? "" : "s"}. Click a group area, then move its units.")
      persist!
    end

    def activate_movement_area!(area_id:)
      area_id = area_id.to_s
      movement = @state["movement"]
      raise InvalidAction, "No movement action is in progress." unless movement
      return persist! if Array(movement["areas"]).include?(area_id)

      area = Area.find_by(key: area_id)
      raise InvalidAction, "Unknown area #{area_id}." unless area

      movable_units = units.values.select { |unit| unit["location"] == area_id && unit["owner"] == active_player }
      raise InvalidAction, "#{area.name} has no #{player_name(active_player)} units to activate for movement." if movable_units.empty?

      remaining = movement["remaining"].to_i
      raise InvalidAction, "No movement group activations remain for this card." unless remaining.positive?

      movement["areas"] ||= []
      movement["areas"] << area_id
      movement["remaining"] = remaining - 1
      movement["units"] ||= {}
      movement["crossings"] ||= {}
      log("#{area.name} activated for movement. #{movement["remaining"]} group activation#{movement["remaining"] == 1 ? "" : "s"} remaining.")
      persist!
    end

    private

    def action_card
      if @state["mode"] == "hotseat"
        @state["revealed"] ? @state.dig("committed", active_player) : @state["selectedCard"]
      else
        active_player == "roman" ? @state["selectedCard"] : nil
      end
    end

    def card_prompt
      @state["mode"] == "hotseat" ? "Select and commit a card first." : "Select a Roman card first."
    end

    def active_player
      @state.fetch("active")
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
