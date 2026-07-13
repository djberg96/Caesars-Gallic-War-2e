require "test_helper"

class GameRules::BattleTest < ActiveSupport::TestCase
  setup do
    GameData::MapSeeder.seed!
    GameData::UnitTypeSeeder.seed!
  end

  test "opens a battle board and resolves an active unit fire action" do
    session = GameSession.create!(data: battle_state)
    session.sync_from_data!

    result = GameRules::Battle.new(session: session, state: session.data).resolve!

    assert_equal "allobroges", result.dig("battle", "area")
    assert_equal "field", result.dig("battle", "phase")
    assert_equal "legion_vii", result.dig("battle", "activeUnit")

    result = GameRules::Battle.new(session: session, state: result, rolls: [1]).act!(
      action: "fire",
      unit_id: "legion_vii"
    )

    assert_equal "eliminated", result.dig("units", "allobroges", "location")
    assert result["diceRolledThisTurn"]
    assert_empty result["undoStack"]
    assert_equal "regroup", result.dig("battle", "phase")
    assert_equal "fire", result.dig("battle", "lastAction", "type")
    assert_equal [1], result.dig("battle", "lastAction", "rolls")
    assert_equal 1, result.dig("battle", "lastAction", "hits")
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

  test "round limit moves the battle board to regroup for the defender" do
    state = battle_state
    state["units"]["legion_vii"]["fire"] = 0
    state["units"]["allobroges"]["fire"] = 0
    state["movement"] = {
      "areas" => ["transalpine_gaul"],
      "remaining" => 0,
      "units" => {
        "legion_vii" => { "origin" => "transalpine_gaul", "steps" => 2, "stopped" => true }
      },
      "crossings" => { "transalpine_gaul->allobroges" => 1 }
    }
    session = GameSession.create!(data: state)

    result = GameRules::Battle.new(session: session, state: session.data, rolls: Array.new(6, 6)).resolve!
    until result.dig("battle", "phase") == "regroup"
      result = GameRules::Battle.new(session: session, state: result, rolls: Array.new(6, 6)).act!(
        action: "fire",
        unit_id: result.dig("battle", "activeUnit")
      )
    end

    assert_match "reached the round limit", result["log"].join(" ")
    assert_equal "regroup", result.dig("battle", "phase")
    assert_equal "barbarian", result.dig("battle", "winner")
    assert_equal ["transalpine_gaul"], result.dig("movement", "areas")
  end

  test "defending units that moved into battle start in reserve" do
    state = battle_state
    state["units"]["legion_viii"] = state["units"]["legion_vii"].merge(
      "id" => "legion_viii",
      "name" => "Legion VIII",
      "location" => "allobroges"
    )
    state["units"]["allobroges"]["owner"] = "barbarian"
    state["active"] = "barbarian"
    state["movement"] = {
      "units" => {
        "legion_viii" => { "origin" => "transalpine_gaul", "steps" => 1, "stopped" => true }
      }
    }
    session = GameSession.create!(data: state)

    result = GameRules::Battle.new(session: session, state: session.data).resolve!

    assert_includes result.dig("battle", "reserves"), "legion_viii"
    assert_not_includes result.dig("battle", "reserves"), "legion_vii"
  end

  test "attacking player chooses which moved group is main" do
    state = battle_state
    state["units"]["legion_viii"] = state["units"]["legion_vii"].merge(
      "id" => "legion_viii",
      "name" => "Legion VIII",
      "location" => "allobroges"
    )
    state["movement"] = {
      "units" => {
        "legion_vii" => { "origin" => "transalpine_gaul", "steps" => 1, "stopped" => true },
        "legion_viii" => { "origin" => "helvetii", "steps" => 1, "stopped" => true }
      }
    }
    session = GameSession.create!(data: state)

    result = GameRules::Battle.new(session: session, state: session.data).resolve!(main_origin: "helvetii")

    assert_includes result.dig("battle", "reserves"), "legion_vii"
    assert_not_includes result.dig("battle", "reserves"), "legion_viii"
    assert_equal "helvetii", result.dig("battle", "mainOrigin")
  end

  test "bot home defender starts in fort and fires during the first round" do
    state = battle_state
    state["units"] = {
      "legion_vii" => roman_legion("legion_vii", "Legion VII", "sequani"),
      "legion_viii" => roman_legion("legion_viii", "Legion VIII", "sequani"),
      "sequani" => {
        "id" => "sequani",
        "name" => "Sequani",
        "type" => "barbarian",
        "owner" => "barbarian",
        "location" => "sequani",
        "home" => "sequani",
        "step" => 0,
        "strengths" => [1, 0],
        "initiative" => "D",
        "fire" => 1
      }
    }
    state["mode"] = "solitaire"
    state["movement"] = {
      "units" => {
        "legion_vii" => { "origin" => "allobroges", "steps" => 1, "stopped" => true },
        "legion_viii" => { "origin" => "allobroges", "steps" => 1, "stopped" => true }
      }
    }
    session = GameSession.create!(data: state)

    result = GameRules::Battle.new(session: session, state: session.data, rolls: Array.new(10, 6)).resolve!
    assert_includes result.dig("battle", "fort"), "sequani"
    assert_match "Sequani starts inside bibracte", result["log"].join(" ")

    2.times do
      result = GameRules::Battle.new(session: session, state: result, rolls: Array.new(10, 6)).act!(
        action: "fire",
        unit_id: result.dig("battle", "activeUnit")
      )
    end

    assert_includes result.dig("battle", "fort"), "sequani"
    assert_match "Sequani fires", result["log"].join(" ")
    assert_no_match "Sequani passes", result["log"].join(" ")
  end

  test "fort defenders require two hits for one step loss" do
    state = battle_state
    state["units"] = {
      "legion_vii" => roman_legion("legion_vii", "Legion VII", "sequani").merge("fire" => 6),
      "sequani" => {
        "id" => "sequani",
        "name" => "Sequani",
        "type" => "barbarian",
        "owner" => "barbarian",
        "location" => "sequani",
        "home" => "sequani",
        "step" => 0,
        "strengths" => [1, 0],
        "initiative" => "D",
        "fire" => 1
      }
    }
    state["mode"] = "solitaire"
    state["movement"] = {
      "units" => {
        "legion_vii" => { "origin" => "allobroges", "steps" => 1, "stopped" => true }
      }
    }
    session = GameSession.create!(data: state)

    result = GameRules::Battle.new(session: session, state: session.data).resolve!
    result = GameRules::Battle.new(session: session, state: result, rolls: [1]).act!(
      action: "fire",
      unit_id: "legion_vii"
    )

    assert_equal 0, result.dig("units", "sequani", "step")
    assert_equal 1, result.dig("battle", "halfHits", "sequani")
    legion_fire = result.dig("battle", "actionResults").find { |entry| entry["unitId"] == "legion_vii" }
    assert_equal 1, legion_fire["hits"]
    assert_equal 0, legion_fire["appliedHits"]
  end

  private

  def roman_legion(id, name, location)
    {
      "id" => id,
      "name" => name,
      "type" => "roman",
      "owner" => "roman",
      "location" => location,
      "home" => "transalpine_gaul",
      "step" => 0,
      "strengths" => [1],
      "initiative" => "A",
      "fire" => 0
    }
  end

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
