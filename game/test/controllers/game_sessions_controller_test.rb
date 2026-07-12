require "test_helper"

class GameSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    GameData::MapSeeder.seed!
  end

  test "creates a persisted game session" do
    assert_difference "GameSession.count", 1 do
      post game_sessions_url(host: "localhost"), params: { state: base_state }, as: :json
    end

    assert_response :success
    body = JSON.parse(response.body)
    assert body["game_session_id"]
    assert_equal "roman", body.dig("state", "active")
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
      log: []
    }
  end
end
