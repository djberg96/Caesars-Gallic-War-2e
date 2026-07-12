require "test_helper"

class GameRules::BattleTest < ActiveSupport::TestCase
  setup do
    GameData::MapSeeder.seed!
    GameData::UnitTypeSeeder.seed!
  end

  test "resolves contested areas and persists eliminated units" do
    session = GameSession.create!(data: battle_state)
    session.sync_from_data!

    result = GameRules::Battle.new(session: session, state: session.data, rolls: [1]).resolve!

    assert_equal "eliminated", result.dig("units", "allobroges", "location")
    assert result["diceRolledThisTurn"]
    assert_empty result["undoStack"]
    assert_match "eliminated", result["log"].join(" ")

    session.reload
    assert session.dice_rolled_this_turn
    assert_equal "eliminated", session.game_units.joins(:unit_type).find_by!(unit_type: { key: "allobroges" }).location
  end

  test "logs when no battles are present" do
    state = battle_state
    state["units"]["allobroges"]["location"] = "helvetii"
    session = GameSession.create!(data: state)

    result = GameRules::Battle.new(session: session, state: session.data).resolve!

    assert_match "No battles", result["log"].first
    assert_not result["diceRolledThisTurn"]
  end

  private

  def battle_state
    {
      "active" => "roman",
      "supply" => 15,
      "vp" => 5,
      "diceRolledThisTurn" => false,
      "undoStack" => [{ "kind" => "move" }],
      "units" => {
        "legion_vii" => {
          "id" => "legion_vii",
          "name" => "Legion VII",
          "type" => "roman",
          "owner" => "roman",
          "location" => "allobroges",
          "home" => "transalpine_gaul",
          "step" => 0,
          "strengths" => [1],
          "initiative" => "A",
          "fire" => 6
        },
        "allobroges" => {
          "id" => "allobroges",
          "name" => "Allobroges",
          "type" => "barbarian",
          "owner" => "barbarian",
          "location" => "allobroges",
          "home" => "allobroges",
          "step" => 0,
          "strengths" => [1, 0],
          "initiative" => "D",
          "fire" => 1
        }
      },
      "log" => []
    }
  end
end
