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
    assert_match %r{Blocks/Markers/Ambiorix_Home_Area-[a-f0-9]+\.svg}, response.body
    assert_match %r{Blocks/Markers/Dumnorix_Home_Area-[a-f0-9]+\.svg}, response.body
    assert_match %r{Blocks/Markers/Turn-[a-f0-9]+\.svg}, response.body
    assert_select "#track-marker-layer"
    assert_select "#discard-zone" do
      assert_select "#discard-title", text: /Discard Pile/
      assert_select "#discard-count", text: "0"
      assert_select "#discard-pile[aria-label='Discard pile']"
    end
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
    assert_select ".board-toolbar details#options-menu.toolbar-options-menu" do
      assert_select "summary", text: "Options"
      assert_select "#yearly-objectives-toggle", text: "Historical Objectives" do
        assert_select "input#yearly-objectives[type='checkbox']"
      end
      assert_select "#historical-reinforcements-toggle", text: "Historical Reinforcements" do
        assert_select "input#historical-reinforcements[type='checkbox']"
      end
      assert_select "#post-game-report-toggle", text: "Post-game Session Report" do
        assert_select "input#post-game-report[type='checkbox']"
      end
      assert_select "#animated-dice-toggle", text: /Animated Dice/ do
        assert_select "input#animated-dice[type='checkbox']"
      end
      assert_select "#movement-sounds-toggle", text: "Movement Sounds" do
        assert_select "input#movement-sounds[type='checkbox']"
      end
      assert_select "#computer-action-zoom-toggle", text: "Computer Action Zoom" do
        assert_select "input#computer-action-zoom[type='checkbox'][checked]"
      end
    end
    assert_select "#optional-rules-status[hidden] #optional-rules-label"
    assert_select ".board-toolbar details#mode-menu.toolbar-mode-menu" do
      assert_select "summary", text: "Mode"
      assert_select "[data-play-mode='hotseat']", text: "Hotseat"
      assert_select "[data-play-mode='solitaire'][aria-pressed='true']", text: "Solitaire Roman"
      assert_select "[data-play-mode='ai']", text: "AI Opponent"
    end
    assert_select ".board-toolbar input#play-mode[type='hidden'][value='solitaire']"
    assert_select ".board-toolbar details#zoom-menu.toolbar-zoom-menu" do
      assert_select "summary", text: "Zoom"
      assert_select "[data-map-zoom='0.5']", text: "50%"
      assert_select "[data-map-zoom='0.75']", text: "75%"
      assert_select "[data-map-zoom='1'][aria-pressed='true']", text: "100%"
      assert_select "[data-map-zoom='1.25']", text: "125%"
      assert_select "[data-map-zoom='1.5']", text: "150%"
    end
    assert_select ".board-toolbar input#map-zoom[type='hidden'][value='1']"
    assert_select ".board-toolbar #revolt-target-panel[hidden]" do
      assert_select "#revolt-target-title", text: "Revolt"
      assert_select "#revolt-target-instructions"
      assert_select "#cancel-revolt-target", text: "Cancel"
    end
    assert_select ".board-toolbar #retreat-target-panel[hidden]" do
      assert_select "#retreat-target-instructions", text: "Choose a highlighted destination on the map."
      assert_select "#cancel-retreat-target", text: "Back to Battle"
    end
    assert_select ".board-stage > #main-force-target-panel[hidden]" do
      assert_select ".main-force-target-kicker", text: "Choose Main Force"
      assert_select "#main-force-target-title", text: "Attack on Helvetii"
      assert_select "#main-force-target-instructions", text: "Choose a highlighted origin area or outlined unit."
      assert_select "#main-force-target-options"
      assert_select "#cancel-main-force-target", text: "Cancel"
    end
    assert_select "#board > #board-stage > #board-canvas" do
      assert_select "img[alt=?]", "Caesar's Gallic War map"
      assert_select "#area-layer"
      assert_select "#movement-arrow-layer[aria-label='Battle entry arrows']"
      assert_select "#leader-home-marker-layer[aria-label='Leader home areas']"
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
    assert_select "#bot-action-review-dialog[aria-labelledby='bot-action-review-title']" do
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
    assert_select "dialog#unit-history-dialog.unit-history-dialog[aria-labelledby='unit-history-title']" do
      assert_select "#unit-history-counter"
      assert_select "#unit-history-kicker", text: "Unit History"
      assert_select "#unit-history-title"
      assert_select "#unit-history-text"
      assert_select "#unit-history-home"
      assert_select "#unit-history-initiative"
      assert_select "#unit-history-battle-rating"
      assert_select "button[type='submit']", text: "Close"
    end
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
    assert_includes response.body, "Caesar's celebrated Legio X Equestris"
  end

  test "loads a persisted game from its friendly URL" do
    session = GameSession.create!(data: {
      "turn" => 2,
      "phase" => "Card Phase",
      "active" => "roman",
      "supply" => 9,
      "vp" => 4,
      "mode" => "solitaire",
      "units" => {},
      "hands" => { "roman" => [], "barbarian" => [] },
      "discard" => [],
      "log" => ["Persisted game loaded."]
    })

    get game_url(session, host: "localhost")

    assert_response :success
    payload = JSON.parse(css_select("script#game-data").sole.text)
    assert_equal session.id, payload.dig("initialState", "gameSessionId")
    assert_equal 2, payload.dig("initialState", "turn")
    assert_equal 9, payload.dig("initialState", "supply")
    assert_equal 4, payload.dig("initialState", "vp")
    assert_equal ["Persisted game loaded."], payload.dig("initialState", "log")
  end
end
