require "test_helper"

class GameRules::MovementTest < ActiveSupport::TestCase
  setup do
    GameData::MapSeeder.seed!
    GameData::UnitTypeSeeder.seed!
  end

  test "moves a unit and stores the updated session state" do
    session = GameSession.create!(data: base_state)

    result = move(session, "legion_vii", "helvetii")

    assert_equal "helvetii", result.dig("units", "legion_vii", "location")
    assert_equal "helvetii", session.reload.data.dig("units", "legion_vii", "location")
    assert_equal "helvetii", session.game_units.find_by!(unit_type: UnitType.find_by!(key: "legion_vii")).location
    assert_equal 1, result.dig("movement", "crossings", "allobroges->helvetii")
  end

  test "rejects movement before a movement card has been played" do
    state = base_state
    state["movement"] = nil
    session = GameSession.create!(data: state)

    error = assert_raises(GameRules::Movement::InvalidMove) do
      move(session, "legion_vii", "helvetii")
    end

    assert_match "Play a card for movement", error.message
    assert_equal "allobroges", session.reload.data.dig("units", "legion_vii", "location")
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

  test "explains when a unit has already finished movement" do
    state = base_state
    state["movement"]["units"]["legion_vii"] = { "origin" => "allobroges", "steps" => 1, "stopped" => true }
    session = GameSession.create!(data: state)

    error = assert_raises(GameRules::Movement::InvalidMove) do
      move(session, "legion_vii", "sequani")
    end

    assert_match "already finished movement", error.message
  end

  test "explains when no legal route exists" do
    session = GameSession.create!(data: base_state)

    error = assert_raises(GameRules::Movement::InvalidMove) do
      move(session, "legion_vii", "menapi")
    end

    assert_match "no legal route", error.message
  end

  test "spends supply when a roman legion moves a second area" do
    state = base_state
    state["movement"]["areas"] = ["transalpine_gaul"]
    state["movement"]["units"]["legion_vii"] = { "origin" => "transalpine_gaul", "steps" => 1, "stopped" => false }
    session = GameSession.create!(data: state)

    result = move(session, "legion_vii", "helvetii")

    assert_equal 14, result["supply"]
    assert_equal 2, result.dig("movement", "units", "legion_vii", "steps")
    assert result.dig("movement", "units", "legion_vii", "stopped")
  end

  test "allows a roman legion to continue from its activated origin area" do
    state = base_state
    state["units"]["legion_vii"]["location"] = "allobroges"
    state["movement"]["areas"] = ["transalpine_gaul"]
    state["movement"]["units"]["legion_vii"] = { "origin" => "transalpine_gaul", "steps" => 1, "stopped" => false }
    session = GameSession.create!(data: state)

    result = move(session, "legion_vii", "helvetii")

    assert_equal "helvetii", result.dig("units", "legion_vii", "location")
    assert_equal 14, result["supply"]
    assert_equal 2, result.dig("movement", "units", "legion_vii", "steps")
  end

  test "force marches a roman legion two areas and spends supply" do
    state = base_state
    state["units"]["legion_vii"]["location"] = "transalpine_gaul"
    state["movement"]["areas"] = ["transalpine_gaul"]
    session = GameSession.create!(data: state)

    result = move(session, "legion_vii", "sequani")

    assert_equal "sequani", result.dig("units", "legion_vii", "location")
    assert_equal 14, result["supply"]
    assert_equal 2, result.dig("movement", "units", "legion_vii", "steps")
    assert result.dig("movement", "units", "legion_vii", "stopped")
    assert_equal 1, result.dig("movement", "crossings", "transalpine_gaul->allobroges")
    assert_equal 1, result.dig("movement", "crossings", "allobroges->sequani")
    assert_equal "allobroges", result.dig("movement", "units", "legion_vii", "entry")
    assert_equal [
      { "from" => "transalpine_gaul", "to" => "allobroges", "border" => "regular" },
      { "from" => "allobroges", "to" => "sequani", "border" => "regular" }
    ], result.dig("movement", "units", "legion_vii", "path")
  end

  test "rejects moving a legion to its current area without marking it stopped" do
    state = base_state
    state["units"]["legion_xii"] = {
      "id" => "legion_xii",
      "name" => "Legion XII",
      "type" => "roman",
      "owner" => "roman",
      "location" => "transalpine_gaul",
      "step" => 1
    }
    state["movement"]["areas"] = ["transalpine_gaul"]
    session = GameSession.create!(data: state)

    error = assert_raises(GameRules::Movement::InvalidMove) do
      move(session, "legion_xii", "transalpine_gaul")
    end

    assert_match "already in Transalpine Gaul", error.message
    assert_equal "transalpine_gaul", session.reload.data.dig("units", "legion_xii", "location")
    assert_nil session.data.dig("movement", "units", "legion_xii")
  end

  test "allows retreat movement after prior card movement and forbids retreat force march" do
    state = base_state
    state["units"]["legion_xi"]["location"] = "sequani"
    state["movement"] = {
      "areas" => ["sequani"],
      "remaining" => 0,
      "retreat" => true,
      "units" => {},
      "crossings" => {}
    }
    session = GameSession.create!(data: state)

    result = move(session, "legion_xi", "allobroges")

    assert_equal "allobroges", result.dig("units", "legion_xi", "location")
    assert_equal 1, result.dig("movement", "units", "legion_xi", "steps")
    assert result.dig("movement", "units", "legion_xi", "stopped")

    state = result
    state["units"]["legion_vii"]["location"] = "sequani"
    session.update!(data: state)

    error = assert_raises(GameRules::Movement::InvalidMove) do
      move(session, "legion_vii", "transalpine_gaul")
    end

    assert_match "cannot retreat more than one area", error.message
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
