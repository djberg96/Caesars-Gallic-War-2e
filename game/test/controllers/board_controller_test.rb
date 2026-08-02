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
    assert_select ".board-toolbar details#game-menu.toolbar-game-menu" do
      assert_select "summary", text: "Game"
      assert_select ".toolbar-game-menu-items #new-game", text: "New Game"
      assert_select ".toolbar-game-menu-items #import-game", text: "Load"
      assert_select ".toolbar-game-menu-items #export-game", text: "Save"
    end
    assert_select ".board-toolbar #yearly-objectives-toggle" do
      assert_select "input#yearly-objectives[type='checkbox']"
    end
    assert_select ".board-toolbar label#play-mode-label[for='play-mode']", text: "Mode"
    assert_select ".board-toolbar select#play-mode"
    assert_select ".board-toolbar #map-zoom" do
      assert_select "option", text: "50%"
      assert_select "option", text: "75%"
      assert_select "option[selected]", text: "100%"
      assert_select "option", text: "125%"
      assert_select "option", text: "150%"
    end
    assert_select ".board-toolbar #bot-movement-review[hidden]" do
      assert_select "#bot-movement-review-routes"
      assert_select "#continue-bot-movement-review", text: "Continue to Battle"
    end
    assert_select ".board-toolbar #revolt-target-panel[hidden]" do
      assert_select "#revolt-target-title", text: "Revolt"
      assert_select "#revolt-target-instructions"
      assert_select "#cancel-revolt-target", text: "Cancel"
    end
    assert_select ".board-toolbar #retreat-target-panel[hidden]" do
      assert_select "#retreat-target-instructions", text: "Choose a highlighted destination on the map."
      assert_select "#cancel-retreat-target", text: "Back to Battle"
    end
    assert_select ".board-toolbar #main-force-target-panel[hidden]" do
      assert_select "#main-force-target-title", text: "Choose Main Force"
      assert_select "#main-force-target-instructions", text: "Choose a highlighted entry area or outlined unit."
      assert_select "#cancel-main-force-target", text: "Cancel"
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
    assert_select "#bot-action-review-dialog" do
      assert_select "#bot-action-review-card"
      assert_select "#bot-action-review-title"
      assert_select "#bot-action-review-details"
      assert_select "#advance-bot-action-review", text: "Continue"
    end
    assert_select "#battle-transition-dialog[aria-labelledby='battle-transition-title']" do
      assert_select "#battle-transition-title", text: "Next Battle"
      assert_select "#battle-transition-message"
      assert_select "#continue-next-battle", text: "Continue to Battle"
    end
    assert_select "#battle-dialog #battle-zones + #battle-details"
    assert_select "dialog#winter-quarters-dialog", count: 0
    assert_select "form#winter-quarters-form.winter-quarters-panel[hidden]" do
      assert_select "#winter-quarters-summary"
      assert_select "#winter-quarters-selection"
      assert_select "button[type='submit']", text: "Continue End Turn"
    end
    assert_select ".board-panel > form#roman-administration-form", count: 0
    assert_select "dialog#roman-administration-dialog.roman-administration-dialog" do
      assert_select "form#roman-administration-form.roman-administration-modal-form"
      assert_select "#roman-administration-title", text: "Roman Administration"
      assert_select "#roman-administration-options"
      assert_select "#roman-administration-status"
      assert_select "#roman-administration-continue", text: "Continue"
    end
    assert_select ".command-panel .campaign-status"
    assert_select "#hotseat-controls[hidden]"
    assert_select "#bot-card", count: 0
    assert_includes response.body, "Legion X"
  end
end
