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
    assert_equal ["allobroges"], session.game_session_cards.where(location: "roman_hand").joins(:card).pluck("cards.key")
    assert_equal ["event_4_massive_revolt"], session.game_session_cards.where(location: "committed_roman").joins(:card).pluck("cards.key")
  end

  test "creates a new game from database-backed setup data" do
    post game_sessions_url(host: "localhost"), params: { mode: "solitaire" }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    session = GameSession.find(body.fetch("game_session_id"))

    assert_equal "solitaire", body.dig("state", "mode")
    assert_equal 64, session.game_units.count
    assert_equal 5, body.dig("state", "hands", "roman").length
    assert_empty body.dig("state", "hands", "barbarian")
    assert_equal 28, body.dig("state", "botDeck").length
    assert_equal 33, session.game_session_cards.count
    assert_equal "roman", session.game_units.joins(:unit_type).find_by!(unit_type: { key: "legion_x" }).owner
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
  end

  private

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
