require "test_helper"

class GameRules::ActionPhaseTest < ActiveSupport::TestCase
  setup do
    GameData::MapSeeder.seed!
    GameData::UnitTypeSeeder.seed!
    GameData::CardSeeder.seed!
  end

  test "starts movement from the selected card" do
    session = GameSession.create!(data: base_state)

    result = GameRules::ActionPhase.new(session: session, state: session.data).start_movement!

    assert_equal "movement", result["currentAction"]
    assert_equal "roman", result.dig("movement", "player")
    assert_equal "allobroges", result.dig("movement", "cardId")
    assert_equal 1, result.dig("movement", "remaining")
    assert_empty result.dig("movement", "areas")
    assert_equal "movement", session.reload.data["currentAction"]
  end

  test "activates a movement area and spends one group activation" do
    state = base_state.merge(
      "currentAction" => "movement",
      "movement" => {
        "player" => "roman",
        "cardId" => "allobroges",
        "remaining" => 1,
        "areas" => [],
        "units" => {},
        "crossings" => {}
      }
    )
    session = GameSession.create!(data: state)

    result = GameRules::ActionPhase.new(session: session, state: session.data).activate_movement_area!(area_id: "allobroges")

    assert_equal ["allobroges"], result.dig("movement", "areas")
    assert_equal 0, result.dig("movement", "remaining")
    assert_equal ["allobroges"], session.reload.data.dig("movement", "areas")
  end

  test "rejects activation of an area without active player units" do
    state = base_state.merge(
      "movement" => {
        "player" => "roman",
        "cardId" => "allobroges",
        "remaining" => 1,
        "areas" => [],
        "units" => {},
        "crossings" => {}
      }
    )
    session = GameSession.create!(data: state)

    error = assert_raises(GameRules::ActionPhase::InvalidAction) do
      GameRules::ActionPhase.new(session: session, state: session.data).activate_movement_area!(area_id: "helvetii")
    end

    assert_match "has no Roman units", error.message
    assert_empty session.reload.data.dig("movement", "areas")
  end

  test "performs a roman supply action" do
    session = GameSession.create!(data: base_state.merge("supply" => 14))

    result = GameRules::ActionPhase.new(session: session, state: session.data).supply!

    assert_equal 16, result["supply"]
    assert_equal "supply", result["currentAction"]
    assert_match "supply action", result["log"].first
    assert_equal 16, session.reload.supply
  end

  test "activates neutral tribes in the card area" do
    state = base_state
    state["units"]["allobroges"] = {
      "id" => "allobroges",
      "name" => "Allobroges",
      "type" => "barbarian",
      "owner" => "neutral",
      "location" => "allobroges",
      "step" => 1
    }
    session = GameSession.create!(data: state)

    result = GameRules::ActionPhase.new(session: session, state: session.data).activate_neutral!

    assert_equal "roman", result.dig("units", "allobroges", "owner")
    assert_equal 0, result.dig("units", "allobroges", "step")
    assert_equal "activate", result["currentAction"]
    assert_match "activates Allobroges", result["log"].first
    assert_equal "roman", session.reload.game_units.joins(:unit_type).find_by!(unit_type: { key: "allobroges" }).owner
  end

  test "performs a political action and locks undo after rolling dice" do
    state = base_state
    state["selectedArea"] = "allobroges"
    state["undoStack"] = [{ "kind" => "move" }]
    state["units"]["allobroges"] = {
      "id" => "allobroges",
      "name" => "Allobroges",
      "type" => "barbarian",
      "owner" => "neutral",
      "location" => "allobroges",
      "home" => "allobroges",
      "step" => 0
    }
    session = GameSession.create!(data: state)

    result = GameRules::ActionPhase.new(session: session, state: session.data).political!(area_id: "allobroges", roll: 2)

    assert_equal "roman", result.dig("units", "allobroges", "owner")
    assert_equal "allobroges", result.dig("units", "allobroges", "location")
    assert_equal "political", result["currentAction"]
    assert result["diceRolledThisTurn"]
    assert_empty result["undoStack"]
    assert_match "succeeds", result["log"].first
    assert session.reload.dice_rolled_this_turn
  end

  test "resolves baggage train event" do
    state = base_state.merge(
      "supply" => 14,
      "selectedCard" => card_hash("event_0_baggage_train"),
      "hands" => { "roman" => [card_hash("event_0_baggage_train")], "barbarian" => [] }
    )
    session = GameSession.create!(data: state)

    result = GameRules::ActionPhase.new(session: session, state: session.data).event!

    assert_equal 19, result["supply"]
    assert_equal "event", result["currentAction"]
    assert_match "Baggage Train", result["log"].first
    assert_equal 19, session.reload.supply
  end

  test "resolves barbarian massive revolt event" do
    card = card_hash("event_4_massive_revolt")
    state = base_state.merge(
      "active" => "barbarian",
      "mode" => "hotseat",
      "revealed" => true,
      "selectedArea" => "allobroges",
      "selectedCard" => nil,
      "committed" => { "roman" => nil, "barbarian" => card },
      "hands" => { "roman" => [], "barbarian" => [card] }
    )
    state["units"]["allobroges"] = {
      "id" => "allobroges",
      "name" => "Allobroges",
      "type" => "barbarian",
      "owner" => "neutral",
      "location" => "allobroges",
      "home" => "allobroges",
      "step" => 1
    }
    state["units"]["vercingetorix"] = {
      "id" => "vercingetorix",
      "name" => "Vercingetorix",
      "type" => "leader",
      "owner" => "neutral",
      "location" => "offboard",
      "home" => "offboard",
      "step" => 0
    }
    session = GameSession.create!(data: state)

    result = GameRules::ActionPhase.new(session: session, state: session.data).event!(area_id: "allobroges")

    assert_equal "barbarian", result.dig("units", "allobroges", "owner")
    assert_equal 0, result.dig("units", "allobroges", "step")
    assert_equal "allobroges", result.dig("units", "vercingetorix", "location")
    assert_equal "barbarian", result.dig("units", "vercingetorix", "owner")
    assert_match "Massive Revolt resolved", result["log"].first
  end

  private

  def base_state
    {
      "active" => "roman",
      "supply" => 15,
      "mode" => "solitaire",
      "selectedCard" => card_hash("allobroges"),
      "hands" => { "roman" => [card_hash("allobroges")], "barbarian" => [] },
      "committed" => { "roman" => nil, "barbarian" => nil },
      "botDeck" => [],
      "discard" => [],
      "units" => {
        "legion_vii" => {
          "id" => "legion_vii",
          "name" => "Legion VII",
          "type" => "roman",
          "owner" => "roman",
          "location" => "allobroges",
          "step" => 0
        }
      },
      "log" => []
    }
  end

  def card_hash(key)
    Card.find_by!(key: key).game_data.stringify_keys
  end
end
