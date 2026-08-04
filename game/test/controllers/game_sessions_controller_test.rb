require "test_helper"

class GameSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    GameData::MapSeeder.seed!
    GameData::UnitTypeSeeder.seed!
    GameData::CardSeeder.seed!
  end

  test "creates a persisted game session" do
    assert_difference "GameSession.count", 1 do
      post game_sessions_url(host: "localhost"), params: { state: base_state }, as: :json
    end

    assert_response :success
    body = JSON.parse(response.body)
    assert body["game_session_id"]
    assert_equal "roman", body.dig("state", "active")

    session = GameSession.find(body["game_session_id"])
    assert_equal 1, session.game_units.count
    assert_equal "allobroges", session.game_units.sole.location
    assert_equal 3, session.game_session_cards.count
    assert_equal 0, session.turn_index
    assert_equal "Card Phase", session.phase
    assert_equal "roman", session.active_player
    assert_equal 15, session.supply
    assert_equal 0, session.vp
    assert_equal "hotseat", session.mode
    assert_not session.revealed
    assert_not session.dice_rolled_this_turn
    assert_equal 0, session.bot_neutral_activations
    assert_equal ["allobroges"], session.game_session_cards.where(location: "roman_hand").joins(:card).pluck("cards.key")
    assert_equal ["event_4_massive_revolt"], session.game_session_cards.where(location: "committed_roman").joins(:card).pluck("cards.key")
  end

  test "creates a new game from database-backed setup data" do
    post game_sessions_url(host: "localhost"), params: { mode: "solitaire" }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    session = GameSession.find(body.fetch("game_session_id"))

    assert_equal "solitaire", body.dig("state", "mode")
    assert body.dig("state", "turnAnnouncementPending")
    assert_equal 64, session.game_units.count
    assert_equal 5, body.dig("state", "hands", "roman").length
    assert_empty body.dig("state", "hands", "barbarian")
    assert_equal 28, body.dig("state", "botDeck").length
    assert_equal 33, session.game_session_cards.count
    assert_equal "roman", session.game_units.joins(:unit_type).find_by!(unit_type: { key: "legion_x" }).owner
    assert_equal %w[legion_i legion_xiii legion_xiv legion_xv], body.dig("state", "romanForcePool")
    %w[legion_i legion_xiii legion_xiv legion_xv].each do |unit_id|
      assert_equal "offboard", body.dig("state", "units", unit_id, "location")
    end
    assert_equal 0, session.turn_index
    assert_equal "Card Phase", session.phase
    assert_equal "roman", session.active_player
    assert_equal 15, session.supply
    assert_equal 0, session.vp
    assert_equal "solitaire", session.mode
    assert_not session.revealed
    assert_not session.dice_rolled_this_turn
    assert_equal 0, session.bot_neutral_activations
  end

  test "acknowledges the current turn announcement" do
    state = base_state.merge(turnAnnouncementPending: true)
    session = GameSession.create!(data: state)

    post acknowledge_turn_game_session_url(session, host: "localhost"), as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_not body.dig("state", "turnAnnouncementPending")
    assert_not session.reload.data["turnAnnouncementPending"]
  end

  test "enables optional rules when creating a new game" do
    post game_sessions_url(host: "localhost"),
         params: { mode: "solitaire", yearly_objectives: true, historical_reinforcements: true },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert body.dig("state", "options", "yearlyObjectives")
    assert body.dig("state", "options", "historicalReinforcements")
    assert_empty body.dig("state", "yearlyObjectiveProgress")
    assert_empty body.dig("state", "yearlyObjectiveHistory")
    assert_match "Yearly Objectives optional rule enabled", body.dig("state", "log").join(" ")
    assert_match "Historical Reinforcements optional rule enabled", body.dig("state", "log").join(" ")
  end

  test "moves through the session API" do
    session = GameSession.create!(data: base_state)

    post move_game_session_url(session, host: "localhost"),
         params: { state: session.data, unit_id: "legion_vii", target: "helvetii" },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "helvetii", body.dig("state", "units", "legion_vii", "location")
    assert_equal "helvetii", session.reload.data.dig("units", "legion_vii", "location")
    assert_equal "helvetii", session.game_units.sole.location
    assert_equal Area.find_by!(key: "helvetii"), session.game_units.sole.area
    assert_equal "roman", session.active_player
    assert_equal 15, session.supply
  end

  test "rejects moves through the session API before movement starts" do
    state = base_state.merge(movement: nil)
    session = GameSession.create!(data: state)

    post move_game_session_url(session, host: "localhost"),
         params: { state: session.data, unit_id: "legion_vii", target: "helvetii" },
         as: :json

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_match "Play a card for movement", body.fetch("error")
    assert_equal "allobroges", session.reload.data.dig("units", "legion_vii", "location")
  end

  test "starts movement through the session API" do
    state = base_state.merge(
      mode: "solitaire",
      selectedCard: card_hash("allobroges"),
      hands: { roman: [card_hash("allobroges")], barbarian: [] },
      committed: { roman: nil, barbarian: nil },
      movement: nil
    )
    session = GameSession.create!(data: state)
    session.sync_from_data!

    post start_movement_game_session_url(session, host: "localhost"),
         params: { state: session.data },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)
    session.reload

    assert_equal "movement", body.dig("state", "currentAction")
    assert_equal "roman", body.dig("state", "movement", "player")
    assert_equal "allobroges", body.dig("state", "movement", "cardId")
    assert_equal 2, body.dig("state", "movement", "remaining")
    assert_equal "movement", session.data["currentAction"]
    assert_equal 15, session.supply
  end

  test "activates a movement area through the session API" do
    state = base_state.merge(
      movement: {
        areas: [],
        remaining: 1,
        units: {},
        crossings: {}
      }
    )
    session = GameSession.create!(data: state)
    session.sync_from_data!

    post activate_movement_area_game_session_url(session, host: "localhost"),
         params: { state: session.data, area_id: "allobroges" },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)

    assert_equal ["allobroges"], body.dig("state", "movement", "areas")
    assert_equal 0, body.dig("state", "movement", "remaining")
    assert_equal ["allobroges"], session.reload.data.dig("movement", "areas")
  end

  test "undoes a move through the session API" do
    state = base_state.merge(
      supply: 14,
      diceRolledThisTurn: false,
      undoStack: [
        {
          kind: "move",
          unitId: "legion_vii",
          from: "allobroges",
          to: "helvetii",
          units: base_state[:units],
          supply: 15,
          movement: base_state[:movement],
          selectedUnit: "legion_vii",
          selectedArea: "allobroges"
        }
      ]
    )
    state[:units] = state[:units].deep_dup
    state[:units][:legion_vii] = state[:units][:legion_vii].merge(location: "helvetii")
    session = GameSession.create!(data: state)
    session.sync_from_data!

    post undo_move_game_session_url(session, host: "localhost"),
         params: { state: session.data },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)
    session.reload

    assert_equal "allobroges", body.dig("state", "units", "legion_vii", "location")
    assert_equal 15, body.dig("state", "supply")
    assert_empty body.dig("state", "undoStack")
    assert_equal "allobroges", session.game_units.sole.location
    assert_equal 15, session.supply
  end

  test "performs a supply action through the session API" do
    state = base_state.merge(
      mode: "solitaire",
      supply: 14,
      selectedCard: card_hash("allobroges"),
      hands: { roman: [card_hash("allobroges")], barbarian: [] },
      committed: { roman: nil, barbarian: nil },
      movement: nil
    )
    session = GameSession.create!(data: state)
    session.sync_from_data!

    post supply_action_game_session_url(session, host: "localhost"),
         params: { state: session.data },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)

    assert_equal 18, body.dig("state", "supply")
    assert_equal "supply", body.dig("state", "currentAction")
    assert_equal 18, session.reload.supply
  end

  test "activates neutral tribes through the session API" do
    state = base_state.merge(
      mode: "solitaire",
      selectedCard: card_hash("allobroges"),
      hands: { roman: [card_hash("allobroges")], barbarian: [] },
      committed: { roman: nil, barbarian: nil },
      movement: nil
    )
    state[:units][:allobroges] = {
      id: "allobroges",
      name: "Allobroges",
      type: "barbarian",
      owner: "neutral",
      location: "allobroges",
      step: 1
    }
    session = GameSession.create!(data: state)
    session.sync_from_data!

    post activate_neutral_game_session_url(session, host: "localhost"),
         params: { state: session.data },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)

    assert_equal "roman", body.dig("state", "units", "allobroges", "owner")
    assert_equal 0, body.dig("state", "units", "allobroges", "step")
    assert_equal "activate", body.dig("state", "currentAction")
    assert_equal "roman", session.reload.game_units.joins(:unit_type).find_by!(unit_type: { key: "allobroges" }).owner
  end

  test "performs a political action through the session API" do
    state = base_state.merge(
      mode: "solitaire",
      selectedArea: "allobroges",
      selectedCard: card_hash("allobroges"),
      hands: { roman: [card_hash("allobroges")], barbarian: [] },
      committed: { roman: nil, barbarian: nil },
      movement: nil,
      undoStack: [{ kind: "move" }]
    )
    state[:units][:allobroges] = {
      id: "allobroges",
      name: "Allobroges",
      type: "barbarian",
      owner: "neutral",
      location: "allobroges",
      home: "allobroges",
      step: 0
    }
    session = GameSession.create!(data: state)
    session.sync_from_data!

    post political_action_game_session_url(session, host: "localhost"),
         params: { state: session.data, area_id: "allobroges", roll: 2 },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)
    session.reload

    assert_equal "roman", body.dig("state", "units", "allobroges", "owner")
    assert_equal "political", body.dig("state", "currentAction")
    assert body.dig("state", "diceRolledThisTurn")
    assert_empty body.dig("state", "undoStack")
    assert session.dice_rolled_this_turn
    assert_equal "roman", session.game_units.joins(:unit_type).find_by!(unit_type: { key: "allobroges" }).owner
  end

  test "performs an event action through the session API" do
    card = card_hash("event_0_baggage_train")
    state = base_state.merge(
      mode: "solitaire",
      supply: 14,
      selectedCard: card,
      hands: { roman: [card], barbarian: [] },
      committed: { roman: nil, barbarian: nil },
      botDeck: [],
      movement: nil
    )
    session = GameSession.create!(data: state)
    session.sync_from_data!

    post event_action_game_session_url(session, host: "localhost"),
         params: { state: session.data },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)

    assert_equal 19, body.dig("state", "supply")
    assert_equal "event", body.dig("state", "currentAction")
    assert_equal 19, session.reload.supply
  end

  test "performs a roman minor revolt through the session API" do
    card = card_hash("event_1_minor_revolt")
    state = base_state.merge(
      mode: "solitaire",
      selectedCard: card,
      hands: { roman: [card], barbarian: [] },
      committed: { roman: nil, barbarian: nil },
      movement: nil
    )
    state[:units][:osismi] = {
      id: "osismi",
      name: "Osismi",
      type: "barbarian",
      owner: "barbarian",
      location: "veneti",
      home: "osismi",
      step: 1
    }
    session = GameSession.create!(data: state)
    session.sync_from_data!

    post event_action_game_session_url(session, host: "localhost"),
         params: { state: session.data, unit_id: "osismi" },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "osismi", body.dig("state", "units", "osismi", "location")
    assert_equal "neutral", body.dig("state", "units", "osismi", "owner")
    assert_equal 0, body.dig("state", "units", "osismi", "step")
    osismi = session.reload.game_units.joins(:unit_type).find_by!(unit_type: { key: "osismi" })
    assert_equal "neutral", osismi.owner
    assert_equal "osismi", osismi.location
  end

  test "opens and acts on battles through the session API" do
    state = base_state.merge(
      vp: 5,
      diceRolledThisTurn: false,
      undoStack: [{ kind: "move" }]
    )
    state[:units][:legion_vii] = state[:units][:legion_vii].merge(
      location: "allobroges",
      strengths: [1],
      initiative: "A",
      fire: 6
    )
    state[:units][:allobroges] = {
      id: "allobroges",
      name: "Allobroges",
      type: "barbarian",
      owner: "barbarian",
      location: "allobroges",
      home: "allobroges",
      step: 0,
      strengths: [1, 0],
      initiative: "D",
      fire: 1
    }
    session = GameSession.create!(data: state)
    session.sync_from_data!

    post resolve_battles_game_session_url(session, host: "localhost"),
         params: { state: session.data },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "allobroges", body.dig("state", "battle", "area")
    assert_equal "legion_vii", body.dig("state", "battle", "activeUnit")

    post battle_action_game_session_url(session, host: "localhost"),
         params: { state: body.fetch("state"), battle_action: "fire", unit_id: "legion_vii", rolls: [1] },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)
    session.reload

    assert_equal "eliminated", body.dig("state", "units", "allobroges", "location")
    assert body.dig("state", "diceRolledThisTurn")
    assert_empty body.dig("state", "undoStack")
    assert_equal "field", body.dig("state", "battle", "phase")
    assert_equal "legion_vii", body.dig("state", "battle", "awaitingRollAcknowledgement")

    post battle_action_game_session_url(session, host: "localhost"),
         params: {
           state: body.fetch("state"),
           battle_action: "acknowledge_roll",
           unit_id: "legion_vii"
         },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "regroup", body.dig("state", "battle", "phase")
    assert session.dice_rolled_this_turn
    assert_equal "eliminated", session.game_units.joins(:unit_type).find_by!(unit_type: { key: "allobroges" }).location
  end

  test "opens the requested battle through the session API" do
    state = base_state.merge(vp: 5)
    state[:units][:legion_vii] = state[:units][:legion_vii].merge(location: "allobroges")
    state[:units][:allobroges] = {
      id: "allobroges",
      name: "Allobroges",
      type: "barbarian",
      owner: "barbarian",
      location: "allobroges",
      home: "allobroges",
      step: 0,
      strengths: [1, 0],
      initiative: "D",
      fire: 1
    }
    state[:units][:legion_viii] = {
      id: "legion_viii",
      name: "Legion VIII",
      type: "roman",
      owner: "roman",
      location: "helvetii",
      home: "transalpine_gaul",
      step: 0,
      strengths: [1],
      initiative: "A",
      fire: 1
    }
    state[:units][:helvetii] = {
      id: "helvetii",
      name: "Helvetii",
      type: "barbarian",
      owner: "barbarian",
      location: "helvetii",
      home: "helvetii",
      step: 0,
      strengths: [1, 0],
      initiative: "D",
      fire: 1
    }
    session = GameSession.create!(data: state)
    session.sync_from_data!

    post resolve_battles_game_session_url(session, host: "localhost"),
         params: { state: session.data, area_id: "helvetii" },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "helvetii", body.dig("state", "battle", "area")
    assert_includes body.dig("state", "battle", "attackers"), "legion_viii"
  end

  test "uses persisted bot battle metadata when the submitted state omits it" do
    state = base_state.merge(active: "roman", pendingBattleEntries: {
      "pictones" => {
        "attacker" => "barbarian",
        "mainOrigin" => "santones",
        "entries" => { "santones" => "santones", "lemovicii" => "santones" }
      }
    })
    state[:units] = {
      pictones: {
        id: "pictones", name: "Pictones", type: "barbarian", owner: "roman",
        location: "pictones", home: "pictones", step: 0, strengths: [3, 2, 1], initiative: "C", fire: 2
      },
      santones: {
        id: "santones", name: "Santones", type: "barbarian", owner: "barbarian",
        location: "pictones", home: "santones", step: 0, strengths: [3, 2, 1], initiative: "C", fire: 2,
        battleEntry: { area: "pictones", attacker: "barbarian", origin: "santones" }
      },
      lemovicii: {
        id: "lemovicii", name: "Lemovicii", type: "barbarian", owner: "barbarian",
        location: "pictones", home: "santones", step: 0, strengths: [2, 1], initiative: "C", fire: 2,
        battleEntry: { area: "pictones", attacker: "barbarian", origin: "santones" }
      }
    }
    session = GameSession.create!(data: state)
    session.sync_from_data!
    submitted = session.data.deep_dup
    submitted.delete("pendingBattleEntries")
    submitted.fetch("units").each_value { |unit| unit.delete("battleEntry") }

    post resolve_battles_game_session_url(session, host: "localhost"),
         params: { state: submitted, area_id: "pictones" },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "barbarian", body.dig("state", "battle", "attacker")
    assert_equal "roman", body.dig("state", "battle", "defender")
    assert_equal "santones", body.dig("state", "battle", "mainOrigin")
    assert_equal "santones", body.dig("state", "battle", "entries", "santones")
    assert_equal "santones", body.dig("state", "battle", "entries", "lemovicii")
  end

  test "draws a bot card through the session API" do
    state = base_state.merge(
      mode: "solitaire",
      botNeutralActivations: 0,
      botDeck: [card_hash("allobroges")],
      discard: [],
      hands: { roman: [], barbarian: [] },
      committed: { roman: nil, barbarian: nil },
      movement: nil
    )
    state[:units][:allobroges] = {
      id: "allobroges",
      name: "Allobroges",
      type: "barbarian",
      owner: "neutral",
      location: "allobroges",
      home: "allobroges",
      step: 0
    }
    session = GameSession.create!(data: state)
    session.sync_from_data!

    post draw_bot_card_game_session_url(session, host: "localhost"),
         params: { state: session.data },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)
    session.reload

    assert_empty body.dig("state", "botDeck")
    assert_equal ["allobroges"], body.dig("state", "discard").map { |card| card.fetch("id") }
    assert_equal ["allobroges"], body.dig("state", "neutralActivationCards", "barbarian").map { |card| card.fetch("id") }
    assert_equal "barbarian", body.dig("state", "units", "allobroges", "owner")
    assert_equal 1, body.dig("state", "botNeutralActivations")
    assert_equal "barbarian", session.game_units.joins(:unit_type).find_by!(unit_type: { key: "allobroges" }).owner
  end

  test "preserves the bot attacker and entry origin through the session API" do
    state = base_state.merge(
      mode: "solitaire",
      botNeutralActivations: 2,
      botDeck: [card_hash("helvetii")],
      discard: [],
      hands: { roman: [], barbarian: [] },
      committed: { roman: nil, barbarian: nil },
      movement: nil,
      units: {
        helvetii: {
          id: "helvetii",
          name: "Helvetii",
          type: "barbarian",
          owner: "barbarian",
          location: "helvetii",
          home: "helvetii",
          step: 0,
          strengths: [8, 6, 4, 2],
          initiative: "C",
          fire: 2
        },
        leuci: {
          id: "leuci",
          name: "Leuci",
          type: "barbarian",
          owner: "roman",
          location: "leuci",
          home: "leuci",
          step: 0,
          strengths: [2, 1],
          initiative: "C",
          fire: 1
        }
      }
    )
    session = GameSession.create!(data: state)
    session.sync_from_data!

    post draw_bot_card_game_session_url(session, host: "localhost"),
         params: { state: session.data },
         as: :json

    assert_response :success
    battle = JSON.parse(response.body).dig("state", "battle")
    assert_equal "leuci", battle.fetch("area")
    assert_equal "barbarian", battle.fetch("attacker")
    assert_equal "roman", battle.fetch("defender")
    assert_equal ["helvetii"], battle.fetch("attackers")
    assert_equal ["leuci"], battle.fetch("defenders")
    assert_equal "helvetii", battle.fetch("mainOrigin")
    assert_equal "helvetii", battle.dig("entries", "helvetii")
  end

  test "deals cards through the session API" do
    session = GameSession.create!(data: base_state.merge(mode: "hotseat"))
    session.sync_from_data!

    post deal_game_session_url(session, host: "localhost"),
         params: { state: session.data },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)
    session.reload

    assert_equal 5, body.dig("state", "hands", "roman").length
    assert_equal 5, body.dig("state", "hands", "barbarian").length
    assert_empty body.dig("state", "botDeck")
    assert_nil body.dig("state", "committed", "roman")
    assert_nil body.dig("state", "movement")
    assert_equal 10, session.game_session_cards.count
    assert_equal 5, session.game_session_cards.where(location: "roman_hand").count
    assert_equal 5, session.game_session_cards.where(location: "barbarian_hand").count
    assert_equal "hotseat", session.mode
    assert_not session.revealed
    assert_not session.dice_rolled_this_turn
    assert_equal 0, session.bot_neutral_activations
  end

  test "deals solitaire bot deck through the session API" do
    session = GameSession.create!(data: base_state.merge(mode: "solitaire"))
    session.sync_from_data!

    post deal_game_session_url(session, host: "localhost"),
         params: { state: session.data },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)

    assert_equal 5, body.dig("state", "hands", "roman").length
    assert_empty body.dig("state", "hands", "barbarian")
    assert_equal 28, body.dig("state", "botDeck").length
    assert_equal 33, session.reload.game_session_cards.count
    assert_equal "solitaire", session.mode
    assert_not session.revealed
    assert_not session.dice_rolled_this_turn
    assert_equal 0, session.bot_neutral_activations
  end

  test "ends the turn through the session API" do
    state = base_state.merge(
      turn: 0,
      vp: 0,
      mode: "hotseat",
      hands: { roman: [], barbarian: [] },
      committed: { roman: nil, barbarian: nil },
      diceRolledThisTurn: true,
      undoStack: [{ kind: "move" }],
      movement: nil
    )
    state[:units][:allobroges] = {
      id: "allobroges",
      name: "Allobroges",
      type: "barbarian",
      owner: "roman",
      location: "allobroges",
      home: "allobroges",
      step: 0
    }
    state[:units][:legion_vii][:home] = "transalpine_gaul"
    session = GameSession.create!(data: state)
    session.sync_from_data!

    post end_turn_game_session_url(session, host: "localhost"),
         params: { state: session.data, harvest_roll: 1, wintering_unit_ids: [] },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "romanSupplyProduction", body.dig("state", "endTurn", "phase")
    assert_equal 2, body.dig("state", "endTurn", "supplyProduction", "produced")
    assert_equal 15, body.dig("state", "endTurn", "supplyProduction", "after")

    post end_turn_game_session_url(session, host: "localhost"),
         params: {
           state: body.fetch("state"),
           supply_production_acknowledged: true
         },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)
    session.reload

    assert_equal 1, body.dig("state", "turn")
    assert_equal 15, body.dig("state", "supply")
    assert_equal 1, body.dig("state", "vp")
    assert_equal "transalpine_gaul", body.dig("state", "units", "legion_vii", "location")
    assert_equal 5, body.dig("state", "hands", "roman").length
    assert_equal 5, body.dig("state", "hands", "barbarian").length
    assert_equal 1, session.turn_index
    assert_equal 15, session.supply
    assert_equal 1, session.vp
    assert_not session.dice_rolled_this_turn
    assert_equal 10, session.game_session_cards.count
  end

  test "commits and reveals cards through the session API" do
    state = base_state.merge(
      mode: "hotseat",
      hands: {
        roman: [card_hash("allobroges")],
        barbarian: [card_hash("helvetii")]
      },
      committed: { roman: nil, barbarian: nil },
      revealed: false
    )
    session = GameSession.create!(data: state)
    session.sync_from_data!

    post commit_card_game_session_url(session, host: "localhost"),
         params: { state: session.data, player: "roman", card_id: "allobroges" },
         as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "allobroges", body.dig("state", "committed", "roman", "id")
    assert_equal ["allobroges"], session.reload.game_session_cards.where(location: "committed_roman").joins(:card).pluck("cards.key")

    post commit_card_game_session_url(session, host: "localhost"),
         params: { state: session.reload.data, player: "barbarian", card_id: "helvetii" },
         as: :json
    assert_response :success

    post reveal_cards_game_session_url(session, host: "localhost"),
         params: { state: session.reload.data },
         as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert body.dig("state", "revealed")
    assert session.reload.revealed
    assert_match "Cards revealed", body.dig("state", "log").first
  end

  test "discards a committed hotseat card through the session API" do
    state = base_state.merge(
      mode: "hotseat",
      active: "roman",
      hands: {
        roman: [card_hash("allobroges")],
        barbarian: [card_hash("helvetii")]
      },
      committed: { roman: card_hash("allobroges"), barbarian: card_hash("helvetii") },
      revealed: true
    )
    session = GameSession.create!(data: state)
    session.sync_from_data!

    post discard_card_game_session_url(session, host: "localhost"),
         params: { state: session.data, player: "roman" },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)

    assert_empty body.dig("state", "hands", "roman")
    assert_equal ["allobroges"], body.dig("state", "discard").map { |card| card.fetch("id") }
    assert_nil body.dig("state", "committed", "roman")
    assert body.dig("state", "revealed")
    assert_equal ["allobroges"], session.reload.game_session_cards.where(location: "discard").joins(:card).pluck("cards.key")
    assert session.revealed
  end

  test "discards a solitaire selected card through the session API" do
    state = base_state.merge(
      mode: "solitaire",
      active: "roman",
      hands: { roman: [card_hash("allobroges")], barbarian: [] },
      selectedCard: card_hash("allobroges"),
      committed: { roman: nil, barbarian: nil },
      discard: []
    )
    session = GameSession.create!(data: state)
    session.sync_from_data!

    post discard_card_game_session_url(session, host: "localhost"),
         params: { state: session.data, player: "roman" },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)

    assert_empty body.dig("state", "hands", "roman")
    assert_nil body.dig("state", "selectedCard")
    assert_equal ["allobroges"], body.dig("state", "discard").map { |card| card.fetch("id") }
    assert_equal ["allobroges"], session.reload.game_session_cards.where(location: "discard").joins(:card).pluck("cards.key")
  end

  test "does not discard a card while its battle is unresolved" do
    state = base_state.merge(
      mode: "solitaire",
      active: "roman",
      hands: { roman: [card_hash("allobroges")], barbarian: [] },
      selectedCard: card_hash("allobroges"),
      committed: { roman: nil, barbarian: nil },
      battle: { area: "allobroges", phase: "field" }
    )
    session = GameSession.create!(data: state)

    post discard_card_game_session_url(session, host: "localhost"),
         params: { state: session.data, player: "roman" },
         as: :json

    assert_response :unprocessable_entity
    assert_match "Resolve the battle", JSON.parse(response.body).fetch("error")
    assert_equal ["allobroges"], session.reload.data.dig("hands", "roman").map { |card| card.fetch("id") }
  end

  test "updates optional rules before the first card is played" do
    state = base_state.merge(
      turn: 0,
      options: { yearlyObjectives: false, historicalReinforcements: false },
      movement: nil,
      currentAction: nil,
      battle: nil,
      discard: [],
      committed: { roman: nil, barbarian: nil },
      revealed: false,
      diceRolledThisTurn: false
    )
    session = GameSession.create!(data: state)

    post update_options_game_session_url(session, host: "localhost"),
         params: { yearly_objectives: true, historical_reinforcements: true },
         as: :json

    assert_response :success
    assert JSON.parse(response.body).dig("options", "yearlyObjectives")
    assert JSON.parse(response.body).dig("options", "historicalReinforcements")
    assert session.reload.data.dig("options", "yearlyObjectives")
    assert session.reload.data.dig("options", "historicalReinforcements")
  end

  test "rejects yearly objective changes after a card is played" do
    state = base_state.merge(
      options: { yearlyObjectives: true, historicalReinforcements: true },
      discard: [card_hash("helvetii")]
    )
    session = GameSession.create!(data: state)

    post update_options_game_session_url(session, host: "localhost"),
         params: { yearly_objectives: false, historical_reinforcements: false },
         as: :json

    assert_response :unprocessable_entity
    assert_match "cannot be changed", JSON.parse(response.body).fetch("error")
    assert session.reload.data.dig("options", "yearlyObjectives")
    assert session.reload.data.dig("options", "historicalReinforcements")
  end

  test "preserves the locked yearly objective setting during later actions" do
    state = base_state.merge(
      options: { yearlyObjectives: true, historicalReinforcements: true },
      discard: [card_hash("helvetii")]
    )
    session = GameSession.create!(data: state)
    submitted = session.data.deep_dup
    submitted["options"]["yearlyObjectives"] = false
    submitted["options"]["historicalReinforcements"] = false

    post move_game_session_url(session, host: "localhost"),
         params: { state: submitted, unit_id: "legion_vii", target: "helvetii" },
         as: :json

    assert_response :success
    assert JSON.parse(response.body).dig("state", "options", "yearlyObjectives")
    assert JSON.parse(response.body).dig("state", "options", "historicalReinforcements")
    assert session.reload.data.dig("options", "yearlyObjectives")
    assert session.reload.data.dig("options", "historicalReinforcements")
  end

  test "repairs legacy games that incorrectly returned Nantuates offboard" do
    state = base_state
    state[:units][:helvetii] = {
      id: "helvetii", name: "Helvetii", type: "barbarian", owner: "barbarian",
      location: "offboard", home: "helvetii", strengths: [8, 6, 4, 2], step: 4
    }
    state[:units][:nantuates] = {
      id: "nantuates", name: "Nantuates", type: "barbarian", owner: "roman",
      location: "offboard", home: "offboard", strengths: [2, 1], step: 0
    }
    session = GameSession.create!(data: state)

    post move_game_session_url(session, host: "localhost"),
         params: { state: session.data, unit_id: "legion_vii", target: "helvetii" },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "helvetii", body.dig("state", "units", "nantuates", "home")
    assert_equal "helvetii", body.dig("state", "units", "nantuates", "location")
    assert_equal "roman", body.dig("state", "units", "nantuates", "owner")
  end

  private

  def card_hash(key)
    Card.find_by!(key: key).game_data
  end

  def base_state
    {
      active: "roman",
      supply: 15,
      units: {
        legion_vii: {
          id: "legion_vii",
          name: "Legion VII",
          type: "roman",
          owner: "roman",
          location: "allobroges",
          step: 0
        }
      },
      movement: {
        areas: ["allobroges"],
        remaining: 0,
        units: {},
        crossings: {}
      },
      hands: {
        roman: [
          {
            id: "allobroges",
            title: "Allobroges",
            area: "allobroges",
            ap: 1,
            type: "area"
          },
          {
            id: "event_4_massive_revolt",
            title: "Massive Revolt",
            ap: 1,
            type: "event"
          }
        ],
        barbarian: []
      },
      botDeck: [
        {
          id: "event_0_baggage_train",
          title: "Baggage Train",
          ap: 1,
          type: "event"
        }
      ],
      discard: [],
      committed: {
        roman: {
          id: "event_4_massive_revolt",
          title: "Massive Revolt",
          ap: 1,
          type: "event"
        },
        barbarian: nil
      },
      log: []
    }
  end
end
