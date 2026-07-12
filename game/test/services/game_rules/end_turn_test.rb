require "test_helper"

class GameRules::EndTurnTest < ActiveSupport::TestCase
  setup do
    GameData::MapSeeder.seed!
    GameData::UnitTypeSeeder.seed!
    GameData::CardSeeder.seed!
  end

  test "ends the turn, applies harvest, scores vp, resets units, and deals" do
    session = GameSession.create!(data: base_state)

    result = GameRules::EndTurn.new(session: session, state: session.data, harvest_roll: 6).end_turn!

    assert_equal 1, result["turn"]
    assert_equal 17, result["supply"]
    assert_equal 1, result["vp"]
    assert_equal "transalpine_gaul", result.dig("units", "legion_vii", "location")
    assert_equal "allobroges", result.dig("units", "allobroges", "location")
    assert_equal "roman", result.dig("units", "allobroges", "owner")
    assert_equal "helvetii", result.dig("units", "helvetii", "location")
    assert_equal "neutral", result.dig("units", "helvetii", "owner")
    assert_equal "germania", result.dig("units", "german_tencteri", "location")
    assert_equal 5, result.dig("hands", "roman").length
    assert_equal 5, result.dig("hands", "barbarian").length
    assert_not result["diceRolledThisTurn"]
    assert_equal [], result["undoStack"]

    session.reload
    assert_equal 1, session.turn_index
    assert_equal 17, session.supply
    assert_equal 1, session.vp
    assert_equal "transalpine_gaul", session.game_units.joins(:unit_type).find_by!(unit_type: { key: "legion_vii" }).location
    assert_equal 10, session.game_session_cards.count
  end

  test "rejects ending during an active movement action" do
    session = GameSession.create!(data: base_state.merge("movement" => { "areas" => ["allobroges"] }))

    error = assert_raises(GameRules::EndTurn::InvalidAction) do
      GameRules::EndTurn.new(session: session, state: session.data, harvest_roll: 3).end_turn!
    end

    assert_match "Finish the current movement action", error.message
  end

  private

  def base_state
    {
      "turn" => 0,
      "phase" => "Card Phase",
      "active" => "roman",
      "supply" => 15,
      "vp" => 0,
      "mode" => "hotseat",
      "hands" => { "roman" => [], "barbarian" => [] },
      "committed" => { "roman" => nil, "barbarian" => nil },
      "botDeck" => [],
      "discard" => [],
      "undoStack" => [{ "kind" => "move" }],
      "diceRolledThisTurn" => true,
      "movement" => nil,
      "units" => {
        "legion_vii" => unit("legion_vii", "roman", "roman", "allobroges", "transalpine_gaul"),
        "allobroges" => unit("allobroges", "barbarian", "roman", "allobroges", "allobroges"),
        "helvetii" => unit("helvetii", "barbarian", "barbarian", "eliminated", "helvetii"),
        "german_tencteri" => unit("german_tencteri", "german", "barbarian", "sequani", "germania")
      },
      "log" => []
    }
  end

  def unit(id, type, owner, location, home)
    {
      "id" => id,
      "name" => id.titleize,
      "type" => type,
      "owner" => owner,
      "location" => location,
      "home" => home,
      "step" => 0
    }
  end
end
