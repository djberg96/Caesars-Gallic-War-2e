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
    assert_equal 1, result.dig("battle", "lastAction", "round")
    assert_equal [1], result.dig("battle", "lastAction", "rolls")
    assert_equal 1, result.dig("battle", "lastAction", "hits")
    assert_equal 1, result.dig("battle", "actionResults").last.fetch("round")
    assert_match "eliminated", result["log"].join(" ")

    session.reload
    assert session.dice_rolled_this_turn
    assert_equal "eliminated", session.game_units.joins(:unit_type).find_by!(unit_type: { key: "allobroges" }).location
  end

  test "records yearly objective combat in Britannia" do
    state = battle_state
    state["options"] = { "yearlyObjectives" => true }
    state["yearlyObjectiveProgress"] = {}
    state["units"].each_value { |unit| unit["location"] = "belgae" }
    session = GameSession.create!(data: state)

    result = GameRules::Battle.new(session: session, state: session.data).resolve!

    assert result.dig("yearlyObjectiveProgress", "romanFoughtInBritannia")
    assert_equal ["legion_vii"], result.dig("yearlyObjectiveProgress", "romanLegionsFoughtInBritannia")
  end

  test "limits an amphibious invasion to two rounds and improves defender initiative" do
    state = battle_state
    state["units"].each_value { |unit| unit["location"] = "belgae" }
    state["units"]["legion_vii"]["initiative"] = "D"
    state["units"]["allobroges"]["initiative"] = "C"
    state["movement"] = {
      "units" => {
        "legion_vii" => {
          "origin" => "atrebates", "entry" => "atrebates", "steps" => 1, "stopped" => true, "naval" => true
        }
      }
    }
    session = GameSession.create!(data: state)

    result = GameRules::Battle.new(session: session, state: session.data).resolve!

    assert result.dig("battle", "amphibious")
    assert_equal 2, result.dig("battle", "maxRounds")
    assert_equal "allobroges", result.dig("battle", "activeUnit")
  end

  test "marks fired units until the next battle round" do
    state = battle_state
    state["units"]["legion_vii"]["fire"] = 0
    state["units"]["allobroges"]["fire"] = 0
    session = GameSession.create!(data: state)

    result = GameRules::Battle.new(session: session, state: session.data).resolve!
    result = GameRules::Battle.new(session: session, state: result, rolls: [6, 6, 6, 6]).act!(
      action: "fire",
      unit_id: "legion_vii"
    )

    assert_equal ["legion_vii"], result.dig("battle", "fired")

    result = GameRules::Battle.new(session: session, state: result, rolls: [6]).act!(
      action: "fire",
      unit_id: "allobroges"
    )

    assert_equal 2, result.dig("battle", "round")
    assert_empty result.dig("battle", "fired")
  end

  test "owner chooses which equally strong unit takes a hit" do
    state = battle_state
    state["units"]["helvetii"] = state["units"]["allobroges"].merge(
      "id" => "helvetii",
      "name" => "Helvetii",
      "home" => "helvetii"
    )
    session = GameSession.create!(data: state)

    result = GameRules::Battle.new(session: session, state: session.data).resolve!
    result = GameRules::Battle.new(session: session, state: result, rolls: [1]).act!(
      action: "fire",
      unit_id: "legion_vii"
    )

    assert_equal ["allobroges", "helvetii"], result.dig("battle", "pendingHits", "targetIds").sort
    assert_equal 0, result.dig("units", "allobroges", "step")
    assert_equal 0, result.dig("units", "helvetii", "step")
    assert_not_includes result.dig("battle", "acted"), "legion_vii"

    result = GameRules::Battle.new(session: session, state: result).act!(
      action: "assign_hit",
      target: "helvetii"
    )

    assert_nil result.dig("battle", "pendingHits")
    assert_equal "allobroges", result.dig("units", "allobroges", "location")
    assert_equal "eliminated", result.dig("units", "helvetii", "location")
    assert_includes result.dig("battle", "acted"), "legion_vii"
  end

  test "Roman regular takes a tied hit before a Gallic ally" do
    state = battle_state
    state["active"] = "barbarian"
    state["units"]["allobroges"].merge!("initiative" => "B", "fire" => 6)
    state["units"]["legion_vii"].merge!("initiative" => "D", "strengths" => [2, 1, 0])
    state["units"]["volcae"] = {
      "id" => "volcae",
      "name" => "Volcae",
      "type" => "barbarian",
      "owner" => "roman",
      "location" => "allobroges",
      "home" => "volcae",
      "step" => 0,
      "strengths" => [2, 1, 0],
      "initiative" => "D",
      "fire" => 1
    }
    session = GameSession.create!(data: state)

    result = GameRules::Battle.new(session: session, state: session.data).resolve!
    assert_equal "allobroges", result.dig("battle", "activeUnit")

    result = GameRules::Battle.new(session: session, state: result, rolls: [1]).act!(
      action: "fire",
      unit_id: "allobroges"
    )

    assert_equal 1, result.dig("units", "legion_vii", "step")
    assert_equal 0, result.dig("units", "volcae", "step")
    assert_nil result.dig("battle", "pendingHits")
  end

  test "first-round reserves cannot suffer hits" do
    state = battle_state
    state["units"]["helvetii"] = state["units"]["allobroges"].merge(
      "id" => "helvetii",
      "name" => "Helvetii",
      "home" => "helvetii",
      "strengths" => [3, 2, 1, 0]
    )
    state["movement"] = {
      "units" => {
        "legion_vii" => { "origin" => "transalpine_gaul", "steps" => 1, "stopped" => true },
        "helvetii" => { "origin" => "helvetii", "steps" => 1, "stopped" => true }
      }
    }
    session = GameSession.create!(data: state)

    result = GameRules::Battle.new(session: session, state: session.data).resolve!
    assert_includes result.dig("battle", "reserves"), "helvetii"

    result = GameRules::Battle.new(session: session, state: result, rolls: [1]).act!(
      action: "fire",
      unit_id: "legion_vii"
    )

    assert_equal "eliminated", result.dig("units", "allobroges", "location")
    assert_equal 0, result.dig("units", "helvetii", "step")
  end

  test "defenders in the Alps require two hits per strength loss" do
    state = battle_state
    state["units"].each_value { |unit| unit["location"] = "helvetii" }
    session = GameSession.create!(data: state)

    result = GameRules::Battle.new(session: session, state: session.data).resolve!(area_id: "helvetii")
    result = GameRules::Battle.new(session: session, state: result, rolls: [1]).act!(
      action: "fire",
      unit_id: "legion_vii"
    )

    assert_equal 0, result.dig("units", "allobroges", "step")
    assert_equal 1, result.dig("battle", "halfHits", "allobroges")
    assert_equal 0, result.dig("battle", "lastAction", "appliedHits")
  end

  test "field defenders take hits before units inside a fort" do
    state = battle_state
    state["units"]["allobroges"]["strengths"] = [2, 1, 0]
    state["units"]["helvetii"] = state["units"]["allobroges"].merge(
      "id" => "helvetii",
      "name" => "Helvetii",
      "home" => "helvetii"
    )
    session = GameSession.create!(data: state)

    result = GameRules::Battle.new(session: session, state: session.data).resolve!
    result["battle"]["fort"] = ["helvetii"]
    result = GameRules::Battle.new(session: session, state: result, rolls: [1, 6, 6, 6]).act!(
      action: "fire",
      unit_id: "legion_vii"
    )

    assert_equal 1, result.dig("units", "allobroges", "step")
    assert_equal 0, result.dig("units", "helvetii", "step")
    assert_nil result.dig("battle", "halfHits", "helvetii")
  end

  test "battle cannot continue while the owner is assigning a hit" do
    state = battle_state
    state["units"]["helvetii"] = state["units"]["allobroges"].merge(
      "id" => "helvetii",
      "name" => "Helvetii",
      "home" => "helvetii"
    )
    session = GameSession.create!(data: state)

    result = GameRules::Battle.new(session: session, state: session.data).resolve!
    result = GameRules::Battle.new(session: session, state: result, rolls: [1]).act!(
      action: "fire",
      unit_id: "legion_vii"
    )

    error = assert_raises(GameRules::Battle::InvalidAction) do
      GameRules::Battle.new(session: session, state: result).act!(
        action: "pass",
        unit_id: "legion_vii"
      )
    end

    assert_match "Assign the pending hit", error.message
  end

  test "logs when no battles are present" do
    state = battle_state
    state["units"]["allobroges"]["location"] = "helvetii"
    session = GameSession.create!(data: state)

    result = GameRules::Battle.new(session: session, state: session.data).resolve!

    assert_match "No battles", result["log"].first
    assert_not result["diceRolledThisTurn"]
  end

  test "opens the requested battle when multiple battles are unresolved" do
    state = battle_state
    state["units"]["legion_viii"] = roman_legion("legion_viii", "Legion VIII", "helvetii")
    state["units"]["helvetii"] = {
      "id" => "helvetii",
      "name" => "Helvetii",
      "type" => "barbarian",
      "owner" => "barbarian",
      "location" => "helvetii",
      "home" => "helvetii",
      "step" => 0,
      "strengths" => [1, 0],
      "initiative" => "D",
      "fire" => 1
    }
    session = GameSession.create!(data: state)
    session.sync_from_data!

    result = GameRules::Battle.new(session: session, state: session.data).resolve!(area_id: "helvetii")

    assert_equal "helvetii", result.dig("battle", "area")
    assert_includes result.dig("battle", "attackers"), "legion_viii"
    assert_includes result.dig("battle", "defenders"), "helvetii"
  end

  test "rejects a requested battle area that is not contested" do
    session = GameSession.create!(data: battle_state)

    error = assert_raises(GameRules::Battle::InvalidAction) do
      GameRules::Battle.new(session: session, state: session.data).resolve!(area_id: "helvetii")
    end

    assert_match "Helvetii does not have an unresolved battle", error.message
  end

  test "round limit forces the attacker to retreat" do
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
    until %w[regroup retreat].include?(result.dig("battle", "phase"))
      result = GameRules::Battle.new(session: session, state: result, rolls: Array.new(6, 6)).act!(
        action: "fire",
        unit_id: result.dig("battle", "activeUnit")
      )
    end

    assert_match "reached the round limit", result["log"].join(" ")
    assert_equal "retreat", result.dig("battle", "phase")
    assert_equal "roman", result.dig("battle", "retreating")
    assert_equal "barbarian", result.dig("battle", "winner")
    assert_equal ["transalpine_gaul"], result.dig("movement", "areas")
  end

  test "defeated army must retreat before battle can finish" do
    state = battle_state
    state["battle"] = {
      "area" => "allobroges",
      "round" => 3,
      "maxRounds" => 3,
      "phase" => "retreat",
      "attacker" => "roman",
      "defender" => "barbarian",
      "activeUnit" => nil,
      "acted" => [],
      "actionResults" => [],
      "attackers" => ["legion_vii"],
      "defenders" => ["allobroges"],
      "mainOrigin" => "transalpine_gaul",
      "entries" => { "legion_vii" => "transalpine_gaul" },
      "reserves" => [],
      "fort" => [],
      "halfHits" => {},
      "retreated" => [],
      "crossings" => {},
      "winner" => "barbarian",
      "retreating" => "roman"
    }
    session = GameSession.create!(data: state)

    error = assert_raises(GameRules::Battle::InvalidAction) do
      GameRules::Battle.new(session: session, state: session.data).act!(action: "finish_retreat")
    end
    assert_match "Retreat Legion VII", error.message

    result = GameRules::Battle.new(session: session, state: session.data).act!(
      action: "forced_retreat",
      unit_id: "legion_vii",
      target: "transalpine_gaul"
    )
    assert_equal "transalpine_gaul", result.dig("units", "legion_vii", "location")
    assert_equal "retreat", result.dig("battle", "phase")

    result = GameRules::Battle.new(session: session, state: result).act!(action: "finish_retreat")
    assert_nil result["battle"]
    assert_match "retreat complete", result["log"].join(" ")
  end

  test "solitaire automatically retreats a defeated Barbarian attacker through its entry border" do
    state = battle_state
    state["mode"] = "solitaire"
    state["units"]["legion_vii"]["fire"] = 0
    state["units"]["helvetii"] = {
      "id" => "helvetii",
      "name" => "Helvetii",
      "type" => "barbarian",
      "owner" => "barbarian",
      "location" => "allobroges",
      "home" => "helvetii",
      "step" => 0,
      "strengths" => [1],
      "initiative" => "C",
      "fire" => 0
    }
    state["units"].delete("allobroges")
    state["battle"] = {
      "area" => "allobroges",
      "round" => 3,
      "maxRounds" => 3,
      "phase" => "field",
      "attacker" => "barbarian",
      "defender" => "roman",
      "activeUnit" => "legion_vii",
      "acted" => [],
      "fired" => [],
      "actionResults" => [],
      "attackers" => ["helvetii"],
      "defenders" => ["legion_vii"],
      "mainOrigin" => "helvetii",
      "entries" => { "helvetii" => "helvetii" },
      "reserves" => [],
      "fort" => [],
      "halfHits" => {},
      "retreated" => [],
      "crossings" => {},
      "winner" => nil
    }
    session = GameSession.create!(data: state)

    result = GameRules::Battle.new(session: session, state: session.data, rolls: [6]).act!(
      action: "fire",
      unit_id: "legion_vii"
    )

    assert_nil result["battle"]
    assert_equal "helvetii", result.dig("units", "helvetii", "location")
    assert_match "Helvetii retreats from Allobroges to Helvetii", result["log"].join(" ")
    assert_match "Barbarian retreat complete", result["log"].join(" ")
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

  test "announces when reserves enter at the start of round two" do
    state = battle_state
    state["units"]["legion_vii"]["fire"] = 0
    state["units"]["allobroges"]["fire"] = 0
    state["units"]["legion_viii"] = roman_legion("legion_viii", "Legion VIII", "allobroges")
    state["movement"] = {
      "units" => {
        "legion_vii" => { "origin" => "transalpine_gaul", "entry" => "transalpine_gaul", "steps" => 1, "stopped" => true },
        "legion_viii" => { "origin" => "helvetii", "entry" => "helvetii", "steps" => 1, "stopped" => true }
      }
    }
    session = GameSession.create!(data: state)

    result = GameRules::Battle.new(session: session, state: session.data).resolve!(main_origin: "transalpine_gaul")
    assert_includes result.dig("battle", "reserves"), "legion_viii"

    result = GameRules::Battle.new(session: session, state: result, rolls: [6]).act!(
      action: "fire",
      unit_id: "legion_vii"
    )
    result = GameRules::Battle.new(session: session, state: result, rolls: [6]).act!(
      action: "fire",
      unit_id: "allobroges"
    )

    assert_equal 2, result.dig("battle", "round")
    announcement = result.dig("battle", "actionResults").last
    assert_equal "reserves", announcement["type"]
    assert_equal ["Legion VIII"], announcement["unitNames"]
    assert_match "Reserve Legion VIII enters the battle", result["log"].join(" ")
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
        "legion_vii" => { "origin" => "transalpine_gaul", "entry" => "transalpine_gaul", "steps" => 1, "stopped" => true },
        "legion_viii" => { "origin" => "transalpine_gaul", "entry" => "helvetii", "steps" => 2, "stopped" => true }
      }
    }
    session = GameSession.create!(data: state)

    result = GameRules::Battle.new(session: session, state: session.data).resolve!(main_origin: "helvetii")

    assert_includes result.dig("battle", "reserves"), "legion_vii"
    assert_not_includes result.dig("battle", "reserves"), "legion_viii"
    assert_equal "helvetii", result.dig("battle", "mainOrigin")
    assert_equal "transalpine_gaul", result.dig("battle", "entries", "legion_vii")
    assert_equal "helvetii", result.dig("battle", "entries", "legion_viii")
  end

  test "retreats cannot move into an area the enemy used to enter the battle" do
    state = battle_state
    state["units"]["legion_vii"]["home"] = "transalpine_gaul"
    state["battle"] = {
      "area" => "allobroges",
      "round" => 1,
      "maxRounds" => 3,
      "phase" => "field",
      "attacker" => "roman",
      "defender" => "barbarian",
      "activeUnit" => "allobroges",
      "acted" => [],
      "actionResults" => [],
      "attackers" => ["legion_vii"],
      "defenders" => ["allobroges"],
      "mainOrigin" => "transalpine_gaul",
      "entries" => { "legion_vii" => "transalpine_gaul" },
      "reserves" => [],
      "fort" => [],
      "halfHits" => {},
      "retreated" => [],
      "crossings" => {},
      "winner" => nil
    }
    session = GameSession.create!(data: state)

    error = assert_raises(GameRules::Battle::InvalidAction) do
      GameRules::Battle.new(session: session, state: session.data).act!(
        action: "retreat",
        unit_id: "allobroges",
        target: "transalpine_gaul"
      )
    end

    assert_match "enemy units entered Allobroges from there", error.message
  end

  test "the attacking main origin blocks a defender retreat when per-unit entries are unavailable" do
    state = battle_state
    state["battle"] = {
      "area" => "allobroges",
      "round" => 1,
      "maxRounds" => 3,
      "phase" => "field",
      "attacker" => "roman",
      "defender" => "barbarian",
      "activeUnit" => "allobroges",
      "acted" => [],
      "actionResults" => [],
      "attackers" => ["legion_vii"],
      "defenders" => ["allobroges"],
      "mainOrigin" => "transalpine_gaul",
      "entries" => {},
      "reserves" => [],
      "fort" => [],
      "halfHits" => {},
      "retreated" => [],
      "crossings" => {},
      "winner" => nil
    }
    session = GameSession.create!(data: state)

    error = assert_raises(GameRules::Battle::InvalidAction) do
      GameRules::Battle.new(session: session, state: session.data).act!(
        action: "retreat",
        unit_id: "allobroges",
        target: "transalpine_gaul"
      )
    end

    assert_match "enemy units entered Allobroges from there", error.message
  end

  test "a voluntary retreat cannot enter an enemy or neutral occupied area" do
    state = battle_state
    state["units"]["neutral_helvetii"] = {
      "id" => "neutral_helvetii",
      "name" => "Helvetii",
      "type" => "barbarian",
      "owner" => "neutral",
      "location" => "helvetii",
      "home" => "helvetii",
      "step" => 0,
      "strengths" => [1],
      "initiative" => "C",
      "fire" => 1
    }
    state["battle"] = {
      "area" => "allobroges",
      "round" => 1,
      "maxRounds" => 3,
      "phase" => "field",
      "attacker" => "roman",
      "defender" => "barbarian",
      "activeUnit" => "legion_vii",
      "acted" => [],
      "fired" => [],
      "actionResults" => [],
      "attackers" => ["legion_vii"],
      "defenders" => ["allobroges"],
      "mainOrigin" => "transalpine_gaul",
      "entries" => { "legion_vii" => "transalpine_gaul" },
      "reserves" => [],
      "fort" => [],
      "halfHits" => {},
      "retreated" => [],
      "crossings" => {},
      "winner" => nil
    }
    session = GameSession.create!(data: state)

    error = assert_raises(GameRules::Battle::InvalidAction) do
      GameRules::Battle.new(session: session, state: session.data).act!(
        action: "retreat",
        unit_id: "legion_vii",
        target: "helvetii"
      )
    end

    assert_match "cannot retreat into an enemy or neutral occupied area", error.message
  end

  test "victorious units cannot regroup into an unresolved battle area" do
    state = battle_state
    state["units"]["allobroges"]["location"] = "eliminated"
    state["units"]["legion_viii"] = roman_legion("legion_viii", "Legion VIII", "helvetii")
    state["units"]["helvetii"] = {
      "id" => "helvetii",
      "name" => "Helvetii",
      "type" => "barbarian",
      "owner" => "barbarian",
      "location" => "helvetii",
      "home" => "helvetii",
      "step" => 0,
      "strengths" => [1, 0],
      "initiative" => "D",
      "fire" => 1
    }
    state["battle"] = {
      "area" => "allobroges",
      "round" => 1,
      "maxRounds" => 3,
      "phase" => "regroup",
      "attacker" => "roman",
      "defender" => "barbarian",
      "activeUnit" => nil,
      "acted" => [],
      "actionResults" => [],
      "attackers" => ["legion_vii"],
      "defenders" => [],
      "mainOrigin" => "transalpine_gaul",
      "entries" => { "legion_vii" => "transalpine_gaul" },
      "reserves" => [],
      "fort" => [],
      "halfHits" => {},
      "retreated" => [],
      "crossings" => {},
      "winner" => "roman"
    }
    session = GameSession.create!(data: state)

    error = assert_raises(GameRules::Battle::InvalidAction) do
      GameRules::Battle.new(session: session, state: session.data).act!(
        action: "regroup",
        target: "helvetii"
      )
    end

    assert_match "battle there is still unresolved", error.message
  end

  test "victorious units can hold the battle area during regroup" do
    state = battle_state
    state["units"]["allobroges"]["location"] = "eliminated"
    state["battle"] = {
      "area" => "allobroges",
      "round" => 1,
      "maxRounds" => 3,
      "phase" => "regroup",
      "attacker" => "roman",
      "defender" => "barbarian",
      "activeUnit" => nil,
      "acted" => [],
      "actionResults" => [],
      "attackers" => ["legion_vii"],
      "defenders" => [],
      "mainOrigin" => "transalpine_gaul",
      "entries" => { "legion_vii" => "transalpine_gaul" },
      "reserves" => [],
      "fort" => [],
      "halfHits" => {},
      "retreated" => [],
      "crossings" => {},
      "winner" => "roman"
    }
    session = GameSession.create!(data: state)

    result = GameRules::Battle.new(session: session, state: session.data).act!(action: "regroup")

    assert_nil result["battle"]
    assert_match "holds Allobroges", result["log"].join(" ")
  end

  test "victorious units regroup individually with fresh battle crossing limits" do
    state = battle_state
    state["units"]["allobroges"]["location"] = "eliminated"
    state["units"]["legion_viii"] = roman_legion("legion_viii", "Legion VIII", "allobroges")
    state["movement"] = {
      "crossings" => { "allobroges->helvetii" => 2 },
      "units" => {}
    }
    state["battle"] = {
      "area" => "allobroges",
      "round" => 1,
      "maxRounds" => 3,
      "phase" => "regroup",
      "attacker" => "roman",
      "defender" => "barbarian",
      "activeUnit" => nil,
      "acted" => [],
      "actionResults" => [],
      "attackers" => ["legion_vii", "legion_viii"],
      "defenders" => [],
      "mainOrigin" => "transalpine_gaul",
      "entries" => { "legion_vii" => "transalpine_gaul", "legion_viii" => "transalpine_gaul" },
      "reserves" => [],
      "fort" => [],
      "halfHits" => {},
      "retreated" => [],
      "crossings" => {},
      "winner" => "roman"
    }
    session = GameSession.create!(data: state)

    result = GameRules::Battle.new(session: session, state: session.data).act!(
      action: "regroup",
      unit_id: "legion_vii",
      target: "helvetii"
    )

    assert_equal "helvetii", result.dig("units", "legion_vii", "location")
    assert_equal "allobroges", result.dig("units", "legion_viii", "location")
    assert_equal "regroup", result.dig("battle", "phase")
    assert_equal 1, result.dig("battle", "crossings", "allobroges->helvetii")
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
    result = GameRules::Battle.new(session: session, state: result, rolls: [1, 6]).act!(
      action: "fire",
      unit_id: "legion_vii"
    )

    assert_equal 0, result.dig("units", "sequani", "step")
    assert_equal 1, result.dig("battle", "halfHits", "sequani")
    legion_fire = result.dig("battle", "actionResults").find { |entry| entry["unitId"] == "legion_vii" }
    assert_equal 1, legion_fire["hits"]
    assert_equal 0, legion_fire["appliedHits"]
  end

  test "Caesar's death immediately ends the campaign" do
    GameData::CardSeeder.seed!
    state = battle_state
    caesar = state["units"].delete("legion_vii").merge(
      "id" => "legion_x",
      "name" => "Legion X",
      "fire" => 0
    )
    state["units"]["legion_x"] = caesar
    roman_card = Card.find_by!(key: "allobroges").game_data.stringify_keys
    bot_card = Card.find_by!(key: "helvetii").game_data.stringify_keys
    state["hands"] = { "roman" => [roman_card], "barbarian" => [] }
    state["botDeck"] = [bot_card]
    session = GameSession.create!(data: state)

    result = GameRules::Battle.new(session: session, state: session.data).resolve!
    result = GameRules::Battle.new(session: session, state: result).act!(
      action: "pass",
      unit_id: "legion_x"
    )
    result = GameRules::Battle.new(session: session, state: result, rolls: [1]).act!(
      action: "fire",
      unit_id: "allobroges"
    )

    assert_equal "eliminated", result.dig("units", "legion_x", "location")
    assert_nil result["battle"]
    assert_equal "Game Over", result["phase"]
    assert_equal "barbarian", result.dig("gameOver", "winner")
    assert_equal "Barbarian Instant Victory", result.dig("gameOver", "result")
    assert_equal 5, result.dig("gameOver", "vp")
    assert_empty result.dig("hands", "roman")
    assert_empty result["botDeck"]
    assert_match "Caesar has been killed", result["log"].join(" ")
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
