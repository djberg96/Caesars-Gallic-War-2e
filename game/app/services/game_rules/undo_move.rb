module GameRules
  class UndoMove
    class InvalidUndo < StandardError; end

    def initialize(session:, state:)
      @session = session
      @state = state.deep_dup
    end

    def undo!
      raise InvalidUndo, "Undo is locked because dice have already been rolled this turn." if @state["diceRolledThisTurn"]

      @state["undoStack"] ||= []
      entry = @state["undoStack"].pop
      raise InvalidUndo, "No move to undo." unless entry
      raise InvalidUndo, "Only moves can be undone right now." unless entry["kind"] == "move"

      @state["units"] = entry.fetch("units")
      @state["supply"] = entry.fetch("supply")
      @state["movement"] = entry["movement"]
      @state["selectedUnit"] = entry["selectedUnit"]
      @state["selectedArea"] = entry["selectedArea"]
      log("#{unit_name(entry.fetch("unitId"))} move to #{area_name(entry.fetch("to"))} undone.")
      persist!
    end

    private

    def persist!
      @session.update!(data: @state)
      @session.sync_from_data!
      @state
    end

    def unit_name(unit_id)
      @state.dig("units", unit_id, "name") || unit_id
    end

    def area_name(area_id)
      Area.find_by(key: area_id)&.name || area_id
    end

    def log(message)
      @state["log"] ||= []
      @state["log"].unshift(message)
      @state["log"] = @state["log"].first(80)
    end
  end
end
