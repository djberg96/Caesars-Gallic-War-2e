require "test_helper"

class GameRules::UndoMoveTest < ActiveSupport::TestCase
  setup do
    GameData::MapSeeder.seed!
    GameData::UnitTypeSeeder.seed!
  end

  test "restores the last move snapshot" do
    session = GameSession.create!(data: moved_state)
    session.sync_from_data!

    result = GameRules::UndoMove.new(session: session, state: session.data).undo!

    assert_equal "allobroges", result.dig("units", "legion_vii", "location")
    assert_equal 15, result["supply"]
    assert_equal ["allobroges"], result.dig("movement", "areas")
    assert_empty result["undoStack"]
    assert_match "undone", result["log"].first

    session.reload
    assert_equal "allobroges", session.game_units.joins(:unit_type).find_by!(unit_type: { key: "legion_vii" }).location
    assert_equal 15, session.supply
  end

  test "rejects undo after dice have been rolled" do
    session = GameSession.create!(data: moved_state.merge("diceRolledThisTurn" => true))

    error = assert_raises(GameRules::UndoMove::InvalidUndo) do
      GameRules::UndoMove.new(session: session, state: session.data).undo!
    end

    assert_match "dice", error.message
  end

  private

  def moved_state
    {
      "active" => "roman",
      "supply" => 14,
      "diceRolledThisTurn" => false,
      "units" => {
        "legion_vii" => unit("helvetii")
      },
      "movement" => {
        "areas" => ["allobroges"],
        "remaining" => 0,
        "units" => { "legion_vii" => { "origin" => "allobroges", "steps" => 2, "stopped" => true } },
        "crossings" => { "allobroges->helvetii" => 1 }
      },
      "undoStack" => [
        {
          "kind" => "move",
          "unitId" => "legion_vii",
          "from" => "allobroges",
          "to" => "helvetii",
          "units" => { "legion_vii" => unit("allobroges") },
          "supply" => 15,
          "movement" => {
            "areas" => ["allobroges"],
            "remaining" => 0,
            "units" => {},
            "crossings" => {}
          },
          "selectedUnit" => "legion_vii",
          "selectedArea" => "allobroges"
        }
      ],
      "log" => []
    }
  end

  def unit(location)
    {
      "id" => "legion_vii",
      "name" => "Legion VII",
      "type" => "roman",
      "owner" => "roman",
      "location" => location,
      "home" => "transalpine_gaul",
      "step" => 0
    }
  end
end
