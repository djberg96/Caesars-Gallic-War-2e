require "test_helper"

class GameRules::MovementTest < ActiveSupport::TestCase
  setup do
    GameData::MapSeeder.seed!
  end

  test "moves a unit and stores the updated session state" do
    session = GameSession.create!(data: base_state)

    result = move(session, "legion_vii", "helvetii")

    assert_equal "helvetii", result.dig("units", "legion_vii", "location")
    assert_equal "helvetii", session.reload.data.dig("units", "legion_vii", "location")
    assert_equal 1, result.dig("movement", "crossings", "allobroges->helvetii")
  end

  test "enforces minor river capacity during a movement action" do
    session = GameSession.create!(data: base_state)

    move(session, "legion_vii", "helvetii")
    move(session, "legion_viii", "helvetii")

    error = assert_raises(GameRules::Movement::InvalidMove) do
      move(session, "legion_ix", "helvetii")
    end

    assert_match "No more than 2 units", error.message
    assert_equal "allobroges", session.reload.data.dig("units", "legion_ix", "location")
  end

  test "allows up to four units over a regular black border" do
    session = GameSession.create!(data: base_state(target_area: "sequani"))

    %w[legion_vii legion_viii legion_ix legion_x].each do |unit_id|
      move(session, unit_id, "sequani")
    end

    error = assert_raises(GameRules::Movement::InvalidMove) do
      move(session, "legion_xi", "sequani")
    end

    assert_match "No more than 4 units", error.message
  end

  test "spends supply when a roman legion moves a second area" do
    state = base_state
    state["movement"]["units"]["legion_vii"] = { "origin" => "transalpine_gaul", "steps" => 1, "stopped" => false }
    session = GameSession.create!(data: state)

    result = move(session, "legion_vii", "helvetii")

    assert_equal 14, result["supply"]
    assert_equal 2, result.dig("movement", "units", "legion_vii", "steps")
    assert result.dig("movement", "units", "legion_vii", "stopped")
  end

  private

  def move(session, unit_id, target)
    GameRules::Movement.new(session: session.reload, state: session.data).move!(unit_id: unit_id, target: target)
  end

  def base_state(target_area: "helvetii")
    {
      "active" => "roman",
      "supply" => 15,
      "units" => unit_state,
      "movement" => {
        "areas" => ["allobroges"],
        "remaining" => 0,
        "units" => {},
        "crossings" => {}
      },
      "selectedUnit" => nil,
      "log" => []
    }.tap do |state|
      state["selectedArea"] = target_area
    end
  end

  def unit_state
    %w[legion_vii legion_viii legion_ix legion_x legion_xi].to_h do |unit_id|
      [
        unit_id,
        {
          "id" => unit_id,
          "name" => unit_id.titleize,
          "type" => "roman",
          "owner" => "roman",
          "location" => "allobroges",
          "step" => 0
        }
      ]
    end
  end
end
