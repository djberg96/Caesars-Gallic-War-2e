require "test_helper"

class BoardControllerTest < ActionDispatch::IntegrationTest
  test "renders the playable board shell" do
    get root_url(host: "localhost")

    assert_response :success
    assert_select "h1", "Caesar's Gallic War"
    assert_select "script#game-data"
    assert_includes response.body, "CGW_Map"
    assert_match %r{Cards/allobroges-[a-f0-9]+\.svg}, response.body
    assert_match %r{Blocks/Markers/Roman_Supply-[a-f0-9]+\.svg}, response.body
    assert_match %r{Blocks/Markers/Roman_VP_x1-[a-f0-9]+\.svg}, response.body
    assert_match %r{Blocks/Markers/Roman_VP_x10-[a-f0-9]+\.svg}, response.body
    assert_match %r{Blocks/Markers/Tribes_Controlled-[a-f0-9]+\.svg}, response.body
    assert_match %r{Blocks/Markers/Turn-[a-f0-9]+\.svg}, response.body
    assert_select "#track-marker-layer"
    assert_select ".side-panel h2", text: "Action", count: 0
    assert_select "#toggle-side-panel[aria-expanded='true']"
    assert_select ".board-toolbar #resolve-battles"
    assert_select ".command-panel .campaign-status"
    assert_select "#hotseat-controls[hidden]"
    assert_select "#bot-card", count: 0
    assert_includes response.body, "Legion X"
  end
end
