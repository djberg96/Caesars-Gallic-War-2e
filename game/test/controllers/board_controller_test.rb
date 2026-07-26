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
    assert_select ".board-toolbar #deal-cards", count: 0
    assert_select ".board-toolbar #save-game", count: 0
    assert_select ".board-toolbar #load-game", count: 0
    assert_select ".board-toolbar #import-game", text: "Load"
    assert_select ".board-toolbar #export-game", text: "Save"
    assert_select ".board-toolbar #map-zoom" do
      assert_select "option", text: "50%"
      assert_select "option", text: "75%"
      assert_select "option[selected]", text: "100%"
      assert_select "option", text: "125%"
      assert_select "option", text: "150%"
    end
    assert_select "#board > #board-stage > #board-canvas" do
      assert_select "img[alt=?]", "Caesar's Gallic War map"
      assert_select "#area-layer"
      assert_select "#movement-arrow-layer[aria-label='Battle entry arrows']"
      assert_select "#piece-layer"
    end
    assert_select "#import-dialog #import-form"
    assert_select "#new-game-dialog"
    assert_select "#new-game-dialog #save-new-game", text: "Save & Start New"
    assert_select "#new-game-dialog #discard-new-game", text: "Start Without Saving"
    assert_select "#turn-dialog #turn-dialog-title", text: "Turn 1 (58BC)"
    assert_select "#turn-dialog .turn-dialog-message", text: "New hand of cards dealt."
    assert_select "#turn-dialog #turn-dialog-status[hidden]" do
      assert_select "#turn-dialog-vp", text: "0"
      assert_select "#turn-dialog-supply", text: "15"
    end
    assert_select "#turn-dialog #acknowledge-turn", text: "OK"
    assert_select "#battle-dialog #battle-zones + #battle-details"
    assert_select "dialog#winter-quarters-dialog", count: 0
    assert_select "form#winter-quarters-form.winter-quarters-panel[hidden]" do
      assert_select "#winter-quarters-summary"
      assert_select "#winter-quarters-selection"
      assert_select "button[type='submit']", text: "Continue End Turn"
    end
    assert_select ".command-panel .campaign-status"
    assert_select "#hotseat-controls[hidden]"
    assert_select "#bot-card", count: 0
    assert_includes response.body, "Legion X"
  end
end
