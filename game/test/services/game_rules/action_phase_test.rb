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
