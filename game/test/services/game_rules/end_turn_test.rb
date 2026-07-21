require "test_helper"

class GameRules::EndTurnTest < ActiveSupport::TestCase
  setup do
    GameData::MapSeeder.seed!
    GameData::UnitTypeSeeder.seed!
    GameData::CardSeeder.seed!
  end

  test "ends the turn, applies harvest, scores vp, resets units, and deals" do
    session = GameSession.create!(data: base_state)

    pending = GameRules::EndTurn.new(session: session, state: session.data, harvest_roll: 6).end_turn!

    assert_equal "End of Turn", pending["phase"]
    assert_equal "romanWintering", pending.dig("endTurn", "phase")
    assert_equal 3, pending.dig("endTurn", "garrisonLimit")
    assert_equal "allobroges", pending.dig("units", "legion_vii", "location")

    result = GameRules::EndTurn.new(session: session, state: pending, wintering_unit_ids: []).end_turn!

    assert_equal 1, result["turn"]
    assert_equal 17, result["supply"]
    assert_equal 1, result["vp"]
    assert_equal "transalpine_gaul", result.dig("units", "legion_vii", "location")
    assert_equal "allobroges", result.dig("units", "allobroges", "location")
    assert_equal "roman", result.dig("units", "allobroges", "owner")
    assert_equal "sequani", result.dig("units", "sequani", "location")
    assert_equal "neutral", result.dig("units", "sequani", "owner")
    assert_equal "germania", result.dig("units", "german_tencteri", "location")
    assert_equal 5, result.dig("hands", "roman").length
    assert_equal 5, result.dig("hands", "barbarian").length
    assert_empty result["discard"]
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

  test "rejects ending before the solitaire hand is played" do
    state = base_state
    state["mode"] = "solitaire"
    state["hands"]["roman"] = [{ "id" => "allobroges" }]
    session = GameSession.create!(data: state)

    error = assert_raises(GameRules::EndTurn::InvalidAction) do
      GameRules::EndTurn.new(session: session, state: session.data, harvest_roll: 3).end_turn!
    end

    assert_equal "Play the remaining 1 card before ending the turn.", error.message
  end

  test "rejects ending before both hotseat hands are played" do
    state = base_state
    state["hands"]["barbarian"] = [{ "id" => "helvetii" }, { "id" => "sequani" }]
    session = GameSession.create!(data: state)

    error = assert_raises(GameRules::EndTurn::InvalidAction) do
      GameRules::EndTurn.new(session: session, state: session.data, harvest_roll: 3).end_turn!
    end

    assert_equal "Play the remaining 2 cards before ending the turn.", error.message
  end

  test "completes the campaign after scoring 51 BC without dealing another hand" do
    state = base_state
    state["turn"] = 7
    state["vp"] = 89
    state["mode"] = "solitaire"
    state["hands"] = { "roman" => [], "barbarian" => [] }
    state["botDeck"] = [Card.find_by!(key: "helvetii").game_data.stringify_keys]
    state["units"]["legion_vii"]["location"] = "transalpine_gaul"
    session = GameSession.create!(data: state)

    result = GameRules::EndTurn.new(session: session, state: session.data, harvest_roll: 3).end_turn!

    assert_equal 7, result["turn"]
    assert_equal "Game Over", result["phase"]
    assert_equal "roman", result.dig("gameOver", "winner")
    assert_equal "Minor Roman Victory", result.dig("gameOver", "result")
    assert_equal 90, result.dig("gameOver", "vp")
    assert_empty result.dig("hands", "roman")
    assert_empty result["botDeck"]
    assert_match "Campaign complete: Minor Roman Victory with 90 Roman VP", result["log"].join(" ")

    error = assert_raises(GameRules::EndTurn::InvalidAction) do
      GameRules::EndTurn.new(session: session, state: result).end_turn!
    end
    assert_equal "The campaign is already complete.", error.message
  end

  test "deals the 51 BC hand after completing 52 BC" do
    state = base_state
    state["turn"] = 6
    state["mode"] = "solitaire"
    state["hands"] = { "roman" => [], "barbarian" => [] }
    state["units"]["legion_vii"]["location"] = "transalpine_gaul"
    session = GameSession.create!(data: state)

    result = GameRules::EndTurn.new(session: session, state: session.data, harvest_roll: 3).end_turn!

    assert_equal 7, result["turn"]
    assert_equal "Card Phase", result["phase"]
    assert_nil result["gameOver"]
    assert_equal 5, result.dig("hands", "roman").length
    assert_equal 28, result["botDeck"].length
  end

  test "scores yearly objectives before units return to winter quarters" do
    state = base_state
    state["turn"] = 2
    state["options"] = { "yearlyObjectives" => true }
    state["yearlyObjectiveProgress"] = {}
    state["yearlyObjectiveHistory"] = []
    state["units"]["helvetii"] = unit("helvetii", "barbarian", "roman", "helvetii", "helvetii")
    state["units"]["legion_vii"]["location"] = "helvetii"
    session = GameSession.create!(data: state)

    pending = GameRules::EndTurn.new(session: session, state: session.data, harvest_roll: 3).end_turn!
    result = GameRules::EndTurn.new(session: session, state: pending, wintering_unit_ids: ["legion_vii"]).end_turn!

    assert_equal 3, result["vp"]
    assert_equal "helvetii", result.dig("units", "legion_vii", "location")
    assert_equal ["t3_helvetii_garrison"], result.dig("yearlyObjectiveHistory", 0, "objectives").map { |objective| objective["id"] }
    assert_match "Yearly objective +1 VP", result["log"].join(" ")
  end

  test "eliminated Gallic units return before Roman wintering choices and join the occupier" do
    state = base_state
    state["units"]["legion_vii"]["location"] = "sequani"
    session = GameSession.create!(data: state)

    pending = GameRules::EndTurn.new(session: session, state: session.data, harvest_roll: 3).end_turn!

    assert_equal "sequani", pending.dig("units", "legion_vii", "location")
    assert_equal "sequani", pending.dig("units", "sequani", "location")
    assert_equal "roman", pending.dig("units", "sequani", "owner")
    assert_equal 2, pending.dig("units", "sequani", "step")

    result = GameRules::EndTurn.new(session: session, state: pending, wintering_unit_ids: []).end_turn!

    assert_equal "transalpine_gaul", result.dig("units", "legion_vii", "location")
    assert_equal "roman", result.dig("units", "sequani", "owner")
  end

  test "asks which legions winter and charges supply for those that remain" do
    state = base_state
    state["supply"] = 4
    state["units"]["legion_viii"] = unit("legion_viii", "roman", "roman", "allobroges", "transalpine_gaul")
    session = GameSession.create!(data: state)

    pending = GameRules::EndTurn.new(session: session, state: session.data, harvest_roll: 3).end_turn!
    result = GameRules::EndTurn.new(session: session, state: pending, wintering_unit_ids: ["legion_vii"]).end_turn!

    assert_equal "allobroges", result.dig("units", "legion_vii", "location")
    assert_equal "transalpine_gaul", result.dig("units", "legion_viii", "location")
    assert_equal 3, result["supply"]
    assert_match "Roman Winter Quarters: Legion Vii remain", result["log"].join(" ")
  end

  test "does not offer legions in Germania as winter-quarter choices" do
    state = base_state
    state["units"]["legion_vii"]["location"] = "germania"
    state["units"]["legion_viii"] = unit("legion_viii", "roman", "roman", "allobroges", "transalpine_gaul")
    session = GameSession.create!(data: state)

    pending = GameRules::EndTurn.new(session: session, state: session.data, harvest_roll: 3).end_turn!
    result = GameRules::EndTurn.new(session: session, state: pending, wintering_unit_ids: ["legion_viii"]).end_turn!

    assert_equal ["legion_viii"], pending.dig("endTurn", "eligibleLegions")
    assert_equal "transalpine_gaul", result.dig("units", "legion_vii", "location")
    assert_equal "allobroges", result.dig("units", "legion_viii", "location")
  end

  test "enforces the harvest garrison limit for winter quarters" do
    state = base_state
    state["units"]["legion_viii"] = unit("legion_viii", "roman", "roman", "allobroges", "transalpine_gaul")
    session = GameSession.create!(data: state)
    pending = GameRules::EndTurn.new(session: session, state: session.data, harvest_roll: 1).end_turn!

    error = assert_raises(GameRules::EndTurn::InvalidAction) do
      GameRules::EndTurn.new(
        session: session,
        state: pending,
        wintering_unit_ids: ["legion_vii", "legion_viii"]
      ).end_turn!
    end

    assert_match "Only 1 legion may winter in Allobroges", error.message
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
      "discard" => [Card.find_by!(key: "allobroges").game_data.stringify_keys],
      "undoStack" => [{ "kind" => "move" }],
      "diceRolledThisTurn" => true,
      "movement" => nil,
      "units" => {
        "legion_vii" => unit("legion_vii", "roman", "roman", "allobroges", "transalpine_gaul"),
        "allobroges" => unit("allobroges", "barbarian", "roman", "allobroges", "allobroges"),
        "sequani" => unit("sequani", "barbarian", "barbarian", "eliminated", "sequani").merge("strengths" => [3, 2, 1], "step" => 3),
        "german_tencteri" => unit("german_tencteri", "german", "barbarian", "germania", "germania")
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
