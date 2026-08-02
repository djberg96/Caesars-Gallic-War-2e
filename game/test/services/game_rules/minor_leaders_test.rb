require "test_helper"

class GameRules::MinorLeadersTest < ActiveSupport::TestCase
  setup do
    GameData::MapSeeder.seed!
  end

  test "places Dumnorix in a selected Celtae area after a major revolt" do
    state = state_with(
      turn: 0,
      units: {
        "allobroges" => unit("allobroges", "barbarian", "neutral", "allobroges", "allobroges"),
        "dumnorix" => unit("dumnorix", "leader", "neutral", "offboard", "offboard")
      }
    )

    placement = GameRules::MinorLeaders.new(state: state).place_for_major_revolt!(["allobroges"])

    assert_equal "dumnorix", placement.dig("leader", "id")
    assert_equal "allobroges", state.dig("units", "dumnorix", "home")
    assert_equal "allobroges", state.dig("units", "dumnorix", "location")
    assert_equal "barbarian", state.dig("units", "dumnorix", "owner")
    assert_equal "barbarian", state.dig("units", "allobroges", "owner")
  end

  test "places Dumnorix at the start of solitaire turn five if absent" do
    state = state_with(
      turn: 4,
      units: {
        "allobroges" => unit("allobroges", "barbarian", "roman", "allobroges", "allobroges"),
        "dumnorix" => unit("dumnorix", "leader", "neutral", "offboard", "offboard")
      }
    )

    placement = GameRules::MinorLeaders.new(state: state).place_scheduled!

    assert_equal "allobroges", placement.fetch("area").key
    assert_equal "barbarian", state.dig("units", "allobroges", "owner")
    assert_equal "allobroges", state.dig("units", "dumnorix", "home")
  end

  test "places Ambiorix at the start of solitaire turn six if absent" do
    state = state_with(
      turn: 5,
      units: {
        "atrebates" => unit("atrebates", "barbarian", "neutral", "atrebates", "atrebates"),
        "ambiorix" => unit("ambiorix", "leader", "neutral", "eliminated", "atrebates")
      }
    )

    placement = GameRules::MinorLeaders.new(state: state).place_scheduled!

    assert_equal "atrebates", placement.fetch("area").key
    assert_equal "barbarian", state.dig("units", "atrebates", "owner")
    assert_equal "atrebates", state.dig("units", "ambiorix", "home")
    assert_equal 0, state.dig("units", "ambiorix", "step")
  end

  test "does not repeat a scheduled placement while the leader is in play" do
    state = state_with(
      turn: 4,
      units: {
        "allobroges" => unit("allobroges", "barbarian", "roman", "allobroges", "allobroges"),
        "dumnorix" => unit("dumnorix", "leader", "barbarian", "aedui", "aedui")
      }
    )

    assert_nil GameRules::MinorLeaders.new(state: state).place_scheduled!
    assert_equal "aedui", state.dig("units", "dumnorix", "location")
  end

  private

  def state_with(turn:, units:)
    {
      "mode" => "solitaire",
      "turn" => turn,
      "units" => units
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
      "step" => 0,
      "strengths" => [3, 2, 1]
    }
  end
end
