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

  test "records a yearly objective crossing into Germania" do
    state = base_state(target_area: "germania")
    state["options"] = { "yearlyObjectives" => true }
    state["yearlyObjectiveProgress"] = {}
    state["units"]["legion_vii"]["location"] = "menapi"
    state["movement"]["areas"] = ["menapi"]
    session = GameSession.create!(data: state)

    result = move(session, "legion_vii", "germania")

    assert result.dig("yearlyObjectiveProgress", "romanEnteredGermania")
    assert_equal ["legion_vii"], result.dig("yearlyObjectiveProgress", "romanLegionsEnteredGermania")
  end

  test "moves up to two Roman legions between ports and charges one supply for the invasion" do
    state = base_state(target_area: "belgae")
    state["options"] = { "yearlyObjectives" => true }
    state["yearlyObjectiveProgress"] = {}
    state["movement"]["areas"] = ["atrebates"]
    state["units"].each_value { |unit| unit["location"] = "atrebates" }
    state["units"]["belgae"] = {
      "id" => "belgae", "name" => "Belgae", "type" => "barbarian", "owner" => "neutral",
      "location" => "belgae", "home" => "belgae", "step" => 0
    }
    session = GameSession.create!(data: state)

    first = move(session, "legion_vii", "belgae")
    second = move(session, "legion_viii", "belgae")

    assert_equal "belgae", second.dig("units", "legion_vii", "location")
    assert_equal "belgae", second.dig("units", "legion_viii", "location")
    assert_equal 14, second["supply"]
    assert second.dig("movement", "units", "legion_vii", "naval")
    assert second.dig("movement", "units", "legion_vii", "stopped")
    assert_equal "atrebates", second.dig("movement", "units", "legion_vii", "entry")
    assert_equal 2, second.dig("movement", "crossings", "atrebates->oceanus_britannicus")
    assert second.dig("yearlyObjectiveProgress", "romanEnteredBritannia")

    error = assert_raises(GameRules::Movement::InvalidMove) { move(session, "legion_ix", "belgae") }
    assert_match "No more than 2 units", error.message
    assert_equal 14, session.reload.data["supply"]
  end

  test "moves Caesar and a legion from Esuvii to Britannia by naval invasion" do
    state = base_state(target_area: "belgae")
    state["movement"]["areas"] = ["esuvii"]
    state["supply"] = 2
    state["units"] = {
      "legion_x" => {
        "id" => "legion_x", "name" => "Legion X", "type" => "roman", "owner" => "roman",
        "location" => "esuvii", "step" => 0
      },
      "legion_xii" => {
        "id" => "legion_xii", "name" => "Legion XII", "type" => "roman", "owner" => "roman",
        "location" => "esuvii", "step" => 0
      },
      "belgae" => {
        "id" => "belgae", "name" => "Belgae", "type" => "barbarian", "owner" => "neutral",
        "location" => "belgae", "home" => "belgae", "step" => 0
      }
    }
    session = GameSession.create!(data: state)

    first = move(session, "legion_x", "belgae")
    result = move(session, "legion_xii", "belgae")

    assert_equal "belgae", result.dig("units", "legion_x", "location")
    assert_equal "belgae", result.dig("units", "legion_xii", "location")
    assert first.dig("movement", "units", "legion_x", "naval")
    assert result.dig("movement", "units", "legion_xii", "naval")
    assert_equal 1, result["supply"]
    assert_equal 2, result.dig("movement", "navalDepartures", "esuvii")
    assert_equal 2, result.dig("movement", "crossings", "esuvii->oceanus_britannicus")
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
    state = base_state
    state["supply"] = 0
    session = GameSession.create!(data: state)

    move(session, "legion_vii", "helvetii")
    move(session, "legion_viii", "helvetii")

    error = assert_raises(GameRules::Movement::InvalidMove) do
      move(session, "legion_ix", "helvetii")
    end

    assert_match "No more than 2 units", error.message
    assert_equal "allobroges", session.reload.data.dig("units", "legion_ix", "location")
  end

  test "does not bypass a saturated direct river border with a forced-march detour" do
    state = base_state(target_area: "santones")
    state["movement"]["areas"] = ["tarbelli"]
    state["units"] = {
      "legion_xi" => {
        "id" => "legion_xi", "name" => "Legion XI", "type" => "roman", "owner" => "roman",
        "location" => "tarbelli", "step" => 0
      },
      "legion_xii" => {
        "id" => "legion_xii", "name" => "Legion XII", "type" => "roman", "owner" => "roman",
        "location" => "tarbelli", "step" => 0
      },
      "elusates" => {
        "id" => "elusates", "name" => "Elusates", "type" => "barbarian", "owner" => "roman",
        "location" => "tarbelli", "home" => "tarbelli", "step" => 0
      }
    }
    session = GameSession.create!(data: state)

    move(session, "legion_xii", "santones")
    move(session, "elusates", "santones")

    error = assert_raises(GameRules::Movement::InvalidMove) do
      move(session, "legion_xi", "santones")
    end

    assert_match "No more than 2 units", error.message
    result = session.reload.data
    assert_equal "tarbelli", result.dig("units", "legion_xi", "location")
    assert_nil result.dig("movement", "units", "legion_xi")
    assert_equal 2, result.dig("movement", "crossings", "tarbelli->santones")
    assert_nil result.dig("movement", "crossings", "tarbelli->cadurci")
    assert_equal 15, result["supply"]
  end

  test "allows up to four units over a regular black border" do
    state = base_state(target_area: "sequani")
    state["supply"] = 0
    session = GameSession.create!(data: state)

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
    assert result.dig("movement", "units", "legion_vii", "force")
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
    assert result.dig("movement", "units", "legion_vii", "force")
    assert_equal 1, result.dig("movement", "crossings", "transalpine_gaul->allobroges")
    assert_equal 1, result.dig("movement", "crossings", "allobroges->sequani")
    assert_equal "allobroges", result.dig("movement", "units", "legion_vii", "entry")
    assert_equal [
      { "from" => "transalpine_gaul", "to" => "allobroges", "border" => "regular" },
      { "from" => "allobroges", "to" => "sequani", "border" => "regular" }
    ], result.dig("movement", "units", "legion_vii", "path")
  end

  test "each legion leaving the Roman Off-Map area uses an activation and stops in Transalpine Gaul" do
    state = base_state(target_area: "transalpine_gaul")
    state["movement"] = {
      "areas" => ["roman_off_map"],
      "remaining" => 2,
      "units" => {},
      "crossings" => {}
    }
    state["units"] = %w[legion_i legion_xiii legion_xiv].to_h do |unit_id|
      [
        unit_id,
        {
          "id" => unit_id,
          "name" => unit_id.titleize,
          "type" => "roman",
          "owner" => "roman",
          "location" => "roman_off_map",
          "home" => "roman_off_map",
          "step" => 0
        }
      ]
    end
    session = GameSession.create!(data: state)

    error = assert_raises(GameRules::Movement::InvalidMove) do
      move(session, "legion_i", "allobroges")
    end
    assert_match "may only move from the Roman Off-Map area to Transalpine Gaul", error.message
    assert_equal 2, session.reload.data.dig("movement", "remaining")

    first = move(session, "legion_i", "transalpine_gaul")
    assert_equal 1, first.dig("movement", "remaining")
    assert first.dig("movement", "units", "legion_i", "stopped")
    assert_equal 15, first["supply"]

    error = assert_raises(GameRules::Movement::InvalidMove) do
      move(session, "legion_i", "allobroges")
    end
    assert_match "already finished movement", error.message

    second = move(session, "legion_xiii", "transalpine_gaul")
    assert_equal 0, second.dig("movement", "remaining")
    assert second.dig("movement", "units", "legion_xiii", "stopped")

    error = assert_raises(GameRules::Movement::InvalidMove) do
      move(session, "legion_xiv", "transalpine_gaul")
    end
    assert_match "No group activations remain", error.message
    assert_equal "roman_off_map", session.reload.data.dig("units", "legion_xiv", "location")
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

  test "Ariovistus rolls for original neutral defenders even when another German moves first" do
    state = {
      "active" => "barbarian",
      "supply" => 15,
      "units" => {
        "ariovistus" => german_unit("ariovistus", "Ariovistus"),
        "german_marcomanni" => german_unit("german_marcomanni", "German - Marcomanni"),
        "leuci" => {
          "id" => "leuci",
          "name" => "Leuci",
          "type" => "barbarian",
          "owner" => "neutral",
          "location" => "leuci",
          "home" => "leuci",
          "step" => 0,
          "strengths" => [3, 2, 1]
        }
      },
      "movement" => {
        "areas" => ["germania"],
        "remaining" => 0,
        "units" => {},
        "crossings" => {}
      },
      "selectedUnit" => nil,
      "log" => []
    }
    session = GameSession.create!(data: state)

    first = move(session, "german_marcomanni", "leuci")
    assert_equal "roman", first.dig("units", "leuci", "owner")

    result = move(session, "ariovistus", "leuci", rolls: [1])

    assert_equal "barbarian", result.dig("units", "leuci", "owner")
    assert result["diceRolledThisTurn"]
    assert result.dig("movement", "neutralAttacks", "leuci", "resolved")
    assert_equal(
      [{ "unitId" => "leuci", "roll" => 1, "subdued" => true }],
      result.dig("movement", "neutralAttacks", "leuci", "outcomes")
    )
    assert_match "Ariovistus special ability: rolled 1 for Leuci", result["log"].join(" ")
  end

  private

  def move(session, unit_id, target, rolls: nil)
    GameRules::Movement.new(session: session.reload, state: session.data, rolls: rolls).move!(unit_id: unit_id, target: target)
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

  def german_unit(id, name)
    {
      "id" => id,
      "name" => name,
      "type" => "german",
      "owner" => "barbarian",
      "location" => "germania",
      "home" => "germania",
      "step" => 0,
      "strengths" => [3, 2, 1]
    }
  end
end
