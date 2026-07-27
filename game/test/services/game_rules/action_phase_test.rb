require "test_helper"

class GameRules::ActionPhaseTest < ActiveSupport::TestCase
  setup do
    GameData::MapSeeder.seed!
    GameData::UnitTypeSeeder.seed!
    GameData::CardSeeder.seed!
  end

  test "starts movement from the selected card" do
    session = GameSession.create!(data: base_state)

    result = GameRules::ActionPhase.new(session: session, state: session.data).start_movement!

    assert_equal "movement", result["currentAction"]
    assert_equal "roman", result.dig("movement", "player")
    assert_equal "allobroges", result.dig("movement", "cardId")
    assert_equal 2, result.dig("movement", "remaining")
    assert_empty result.dig("movement", "areas")
    assert_equal "movement", session.reload.data["currentAction"]
  end

  test "activates a movement area and spends one group activation" do
    state = base_state.merge(
      "currentAction" => "movement",
      "movement" => {
        "player" => "roman",
        "cardId" => "allobroges",
        "remaining" => 1,
        "areas" => [],
        "units" => {},
        "crossings" => {}
      }
    )
    session = GameSession.create!(data: state)

    result = GameRules::ActionPhase.new(session: session, state: session.data).activate_movement_area!(area_id: "allobroges")

    assert_equal ["allobroges"], result.dig("movement", "areas")
    assert_equal 0, result.dig("movement", "remaining")
    assert_equal ["allobroges"], session.reload.data.dig("movement", "areas")
  end

  test "selecting the Roman Off-Map area defers activation spending until each legion moves" do
    state = base_state.merge(
      "currentAction" => "movement",
      "movement" => {
        "player" => "roman",
        "cardId" => "allobroges",
        "remaining" => 2,
        "areas" => [],
        "units" => {},
        "crossings" => {}
      }
    )
    state["units"]["legion_i"] = {
      "id" => "legion_i",
      "name" => "Legion I",
      "type" => "roman",
      "owner" => "roman",
      "location" => "roman_off_map",
      "step" => 0
    }
    session = GameSession.create!(data: state)

    result = GameRules::ActionPhase.new(session: session, state: session.data).activate_movement_area!(area_id: "roman_off_map")

    assert_equal ["roman_off_map"], result.dig("movement", "areas")
    assert_equal 2, result.dig("movement", "remaining")
    assert_match "Each legion moved to Transalpine Gaul will use one group activation", result["log"].first
  end

  test "rejects activation of an area without active player units" do
    state = base_state.merge(
      "movement" => {
        "player" => "roman",
        "cardId" => "allobroges",
        "remaining" => 1,
        "areas" => [],
        "units" => {},
        "crossings" => {}
      }
    )
    session = GameSession.create!(data: state)

    error = assert_raises(GameRules::ActionPhase::InvalidAction) do
      GameRules::ActionPhase.new(session: session, state: session.data).activate_movement_area!(area_id: "helvetii")
    end

    assert_match "has no Roman units", error.message
    assert_empty session.reload.data.dig("movement", "areas")
  end

  test "performs a roman supply action" do
    session = GameSession.create!(data: base_state.merge("supply" => 14))

    result = GameRules::ActionPhase.new(session: session, state: session.data).supply!

    assert_equal 18, result["supply"]
    assert_equal "supply", result["currentAction"]
    assert_match "supply action", result["log"].first
    assert_equal 18, session.reload.supply
  end

  test "requires Romans to resolve Baggage Train as an event instead of a supply action" do
    card = card_hash("event_0_baggage_train")
    state = base_state.merge(
      "selectedCard" => card,
      "hands" => { "roman" => [card], "barbarian" => [] }
    )
    session = GameSession.create!(data: state)

    error = assert_raises(GameRules::ActionPhase::InvalidAction) do
      GameRules::ActionPhase.new(session: session, state: session.data).supply!
    end

    assert_equal "Resolve Baggage Train as an event to gain Roman supply.", error.message
    assert_equal 15, session.reload.supply
  end

  test "activates neutral tribes in the card area" do
    state = base_state
    state["units"]["allobroges"] = {
      "id" => "allobroges",
      "name" => "Allobroges",
      "type" => "barbarian",
      "owner" => "neutral",
      "location" => "allobroges",
      "step" => 1
    }
    session = GameSession.create!(data: state)

    result = GameRules::ActionPhase.new(session: session, state: session.data).activate_neutral!

    assert_equal "roman", result.dig("units", "allobroges", "owner")
    assert_equal 0, result.dig("units", "allobroges", "step")
    assert_equal "activate", result["currentAction"]
    assert_equal ["allobroges"], result.dig("neutralActivationCards", "roman").map { |card| card.fetch("id") }
    assert_equal "Allobroges becomes a Roman ally.", result["log"].first
    assert_equal "roman", session.reload.game_units.joins(:unit_type).find_by!(unit_type: { key: "allobroges" }).owner
  end

  test "requires a Roman legion on the northern coast to activate Britannia" do
    state = britannia_action_state
    session = GameSession.create!(data: state)

    error = assert_raises(GameRules::ActionPhase::InvalidAction) do
      GameRules::ActionPhase.new(session: session, state: session.data).activate_neutral!
    end

    assert_match "legion in a port area connected to Oceanus Britannicus", error.message
    assert_equal "neutral", session.reload.data.dig("units", "belgae", "owner")

    state["units"]["legion_vii"]["location"] = "atrebates"
    coastal_session = GameSession.create!(data: state)
    result = GameRules::ActionPhase.new(session: coastal_session, state: coastal_session.data).activate_neutral!

    assert_equal "roman", result.dig("units", "belgae", "owner")
  end

  test "requires a Roman legion on the northern coast for a political action in Britannia" do
    state = britannia_action_state
    session = GameSession.create!(data: state)

    error = assert_raises(GameRules::ActionPhase::InvalidAction) do
      GameRules::ActionPhase.new(session: session, state: session.data).political!(area_id: "belgae", roll: 2)
    end

    assert_match "legion in a port area connected to Oceanus Britannicus", error.message
    assert_equal "neutral", session.reload.data.dig("units", "belgae", "owner")

    state["units"]["legion_vii"]["location"] = "osismi"
    coastal_session = GameSession.create!(data: state)
    result = GameRules::ActionPhase.new(session: coastal_session, state: coastal_session.data).political!(area_id: "belgae", roll: 2)

    assert_equal "roman", result.dig("units", "belgae", "owner")
  end

  test "rejects a second Roman neutral tribe activation in the same year" do
    state = base_state.merge(
      "neutralActivationCards" => { "roman" => [card_hash("andes")], "barbarian" => [] }
    )
    state["units"]["allobroges"] = neutral_allobroges
    session = GameSession.create!(data: state)

    error = assert_raises(GameRules::ActionPhase::InvalidAction) do
      GameRules::ActionPhase.new(session: session, state: session.data).activate_neutral!
    end

    assert_match "yearly neutral tribe activation limit (1)", error.message
    assert_equal "neutral", session.reload.data.dig("units", "allobroges", "owner")
  end

  test "rejects a third Barbarian neutral tribe activation in the same year" do
    card = card_hash("allobroges")
    state = base_state.merge(
      "active" => "barbarian",
      "mode" => "hotseat",
      "revealed" => true,
      "committed" => { "roman" => nil, "barbarian" => card },
      "neutralActivationCards" => {
        "roman" => [],
        "barbarian" => [card_hash("andes"), card_hash("veneti")]
      }
    )
    state["units"]["allobroges"] = neutral_allobroges
    session = GameSession.create!(data: state)

    error = assert_raises(GameRules::ActionPhase::InvalidAction) do
      GameRules::ActionPhase.new(session: session, state: session.data).activate_neutral!
    end

    assert_match "yearly neutral tribe activation limit (2)", error.message
    assert_equal "neutral", session.reload.data.dig("units", "allobroges", "owner")
  end

  test "performs a political action and locks undo after rolling dice" do
    state = base_state
    state["selectedArea"] = "allobroges"
    state["undoStack"] = [{ "kind" => "move" }]
    state["units"]["allobroges"] = {
      "id" => "allobroges",
      "name" => "Allobroges",
      "type" => "barbarian",
      "owner" => "neutral",
      "location" => "allobroges",
      "home" => "allobroges",
      "step" => 0
    }
    session = GameSession.create!(data: state)

    result = GameRules::ActionPhase.new(session: session, state: session.data).political!(area_id: "allobroges", roll: 2)

    assert_equal "roman", result.dig("units", "allobroges", "owner")
    assert_equal "allobroges", result.dig("units", "allobroges", "location")
    assert_equal "political", result["currentAction"]
    assert result["diceRolledThisTurn"]
    assert_empty result["undoStack"]
    assert_match "succeeds", result["log"].first
    assert session.reload.dice_rolled_this_turn
  end

  test "reports when matching card and opposing unit political modifiers cancel" do
    state = base_state
    state["units"]["allobroges"] = {
      "id" => "allobroges",
      "name" => "Allobroges",
      "type" => "barbarian",
      "owner" => "barbarian",
      "location" => "allobroges",
      "home" => "allobroges",
      "step" => 0
    }
    session = GameSession.create!(data: state)

    result = GameRules::ActionPhase.new(session: session, state: session.data).political!(area_id: "allobroges", roll: 3)

    assert_match "rolled 3; matching card -1, opposing unit +1; modified 3", result["log"].first
  end

  test "a successful political action returns the home tribe as the attacker" do
    state = base_state
    state["units"]["allobroges"] = {
      "id" => "allobroges",
      "name" => "Allobroges",
      "type" => "barbarian",
      "owner" => "barbarian",
      "location" => "helvetii",
      "home" => "allobroges",
      "step" => 0,
      "strengths" => [2, 1],
      "initiative" => "C",
      "fire" => 2
    }
    state["units"]["helvetii"] = {
      "id" => "helvetii",
      "name" => "Helvetii",
      "type" => "barbarian",
      "owner" => "barbarian",
      "location" => "allobroges",
      "home" => "helvetii",
      "step" => 0,
      "strengths" => [2, 1],
      "initiative" => "C",
      "fire" => 2
    }
    session = GameSession.create!(data: state)

    result = GameRules::ActionPhase.new(session: session, state: session.data).political!(area_id: "allobroges", roll: 2)

    assert_equal "roman", result.dig("units", "allobroges", "owner")
    assert_equal "allobroges", result.dig("units", "allobroges", "location")
    assert_equal "allobroges", result.dig("battle", "area")
    assert_equal "roman", result.dig("battle", "attacker")
    assert_equal "barbarian", result.dig("battle", "defender")
    assert_includes result.dig("battle", "attackers"), "allobroges"
    assert_includes result.dig("battle", "defenders"), "helvetii"
  end

  test "resolves baggage train event" do
    state = base_state.merge(
      "supply" => 14,
      "selectedCard" => card_hash("event_0_baggage_train"),
      "hands" => { "roman" => [card_hash("event_0_baggage_train")], "barbarian" => [] }
    )
    session = GameSession.create!(data: state)

    result = GameRules::ActionPhase.new(session: session, state: session.data).event!

    assert_equal 19, result["supply"]
    assert_equal "event", result["currentAction"]
    assert_match "Baggage Train", result["log"].first
    assert_equal 19, session.reload.supply
  end

  test "roman minor revolt returns an active barbarian tribe home" do
    card = card_hash("event_1_minor_revolt")
    state = base_state.merge(
      "selectedCard" => card,
      "hands" => { "roman" => [card], "barbarian" => [] }
    )
    state["units"]["osismi"] = {
      "id" => "osismi",
      "name" => "Osismi",
      "type" => "barbarian",
      "owner" => "barbarian",
      "location" => "veneti",
      "home" => "osismi",
      "step" => 1
    }
    session = GameSession.create!(data: state)

    result = GameRules::ActionPhase.new(session: session, state: session.data).event!(unit_id: "osismi")

    assert_equal "osismi", result.dig("units", "osismi", "location")
    assert_equal "neutral", result.dig("units", "osismi", "owner")
    assert_equal 0, result.dig("units", "osismi", "step")
    assert_match "returns home", result["log"].first
    osismi = session.reload.game_units.joins(:unit_type).find_by!(unit_type: { key: "osismi" })
    assert_equal "neutral", osismi.owner
    assert_equal "osismi", osismi.location
  end

  test "roman minor revolt can target a barbarian tribe already at home" do
    card = card_hash("event_1_minor_revolt")
    state = base_state.merge(
      "selectedCard" => card,
      "hands" => { "roman" => [card], "barbarian" => [] }
    )
    state["units"]["atuatuci"] = {
      "id" => "atuatuci",
      "name" => "Atuatuci",
      "type" => "barbarian",
      "owner" => "barbarian",
      "location" => "atuatuci",
      "home" => "atuatuci",
      "step" => 1
    }
    session = GameSession.create!(data: state)

    result = GameRules::ActionPhase.new(session: session, state: session.data).event!(unit_id: "atuatuci")

    assert_equal "atuatuci", result.dig("units", "atuatuci", "location")
    assert_equal "neutral", result.dig("units", "atuatuci", "owner")
    assert_equal 0, result.dig("units", "atuatuci", "step")
  end

  test "Roman revolt makes a returning tribe attack Barbarian occupants in its home area" do
    card = card_hash("event_3_major_revolt")
    state = base_state.merge(
      "selectedCard" => card,
      "hands" => { "roman" => [card], "barbarian" => [] }
    )
    state["units"]["mandubii"] = barbarian_unit(
      id: "mandubii",
      name: "Mandubii",
      owner: "barbarian",
      location: "aedui",
      home: "mandubii",
      strengths: [3, 2, 1]
    )
    state["units"]["senones"] = barbarian_unit(
      id: "senones",
      name: "Senones",
      owner: "barbarian",
      location: "mandubii",
      home: "mandubii",
      strengths: [2, 1]
    )
    session = GameSession.create!(data: state)

    result = GameRules::ActionPhase.new(session: session, state: session.data).event!(unit_id: "mandubii")

    assert_equal "roman", result.dig("units", "mandubii", "owner")
    assert_equal "mandubii", result.dig("units", "mandubii", "location")
    assert_equal "mandubii", result.dig("battle", "area")
    assert_equal "roman", result.dig("battle", "attacker")
    assert_equal ["mandubii"], result.dig("battle", "attackers")
    assert_equal ["senones"], result.dig("battle", "defenders")
    assert_match(/Mandubii.*becomes a Roman ally.*attacks Senones/, result["log"].join(" "))
  end

  test "Roman revolt makes a returning tribe attack Roman occupants as a Barbarian ally" do
    card = card_hash("event_3_major_revolt")
    state = base_state.merge(
      "selectedCard" => card,
      "hands" => { "roman" => [card], "barbarian" => [] }
    )
    state["units"]["mandubii"] = barbarian_unit(
      id: "mandubii",
      name: "Mandubii",
      owner: "barbarian",
      location: "aedui",
      home: "mandubii",
      strengths: [3, 2, 1]
    )
    state["units"]["legion_viii"] = {
      "id" => "legion_viii",
      "name" => "Legion VIII",
      "type" => "roman",
      "owner" => "roman",
      "location" => "mandubii",
      "home" => "transalpine_gaul",
      "initiative" => "A",
      "fire" => 2,
      "strengths" => [4, 3, 2, 1],
      "step" => 0
    }
    session = GameSession.create!(data: state)

    result = GameRules::ActionPhase.new(session: session, state: session.data).event!(unit_id: "mandubii")

    assert_equal "barbarian", result.dig("units", "mandubii", "owner")
    assert_equal "barbarian", result.dig("battle", "attacker")
    assert_equal ["mandubii"], result.dig("battle", "attackers")
    assert_equal ["legion_viii"], result.dig("battle", "defenders")
  end

  test "roman minor revolt cannot target an eliminated tribe" do
    card = card_hash("event_1_minor_revolt")
    state = base_state.merge(
      "selectedCard" => card,
      "hands" => { "roman" => [card], "barbarian" => [] }
    )
    state["units"]["helvetii"] = {
      "id" => "helvetii",
      "name" => "Helvetii",
      "type" => "barbarian",
      "owner" => "barbarian",
      "location" => "eliminated",
      "home" => "helvetii",
      "step" => 0
    }
    session = GameSession.create!(data: state)

    error = assert_raises(GameRules::ActionPhase::InvalidAction) do
      GameRules::ActionPhase.new(session: session, state: session.data).event!(unit_id: "helvetii")
    end

    assert_match "not an active Barbarian-controlled tribe", error.message
  end

  test "resolves barbarian massive revolt event" do
    card = card_hash("event_4_massive_revolt")
    state = base_state.merge(
      "active" => "barbarian",
      "turn" => 1,
      "mode" => "hotseat",
      "revealed" => true,
      "selectedArea" => "allobroges",
      "selectedCard" => nil,
      "committed" => { "roman" => nil, "barbarian" => card },
      "hands" => { "roman" => [], "barbarian" => [card] }
    )
    state["units"]["allobroges"] = {
      "id" => "allobroges",
      "name" => "Allobroges",
      "type" => "barbarian",
      "owner" => "neutral",
      "location" => "allobroges",
      "home" => "allobroges",
      "step" => 1
    }
    state["units"]["vercingetorix"] = {
      "id" => "vercingetorix",
      "name" => "Vercingetorix",
      "type" => "leader",
      "owner" => "neutral",
      "location" => "offboard",
      "home" => "offboard",
      "step" => 0
    }
    session = GameSession.create!(data: state)

    result = GameRules::ActionPhase.new(session: session, state: session.data).event!(area_id: "allobroges")

    assert_equal "barbarian", result.dig("units", "allobroges", "owner")
    assert_equal 0, result.dig("units", "allobroges", "step")
    assert_equal "allobroges", result.dig("units", "vercingetorix", "location")
    assert_equal "barbarian", result.dig("units", "vercingetorix", "owner")
    assert result["massiveRevoltPlayed"]
    assert_match "Massive Revolt resolved", result["log"].first
  end

  test "treats barbarian massive revolt as minor on turn one outside solitaire" do
    card = card_hash("event_4_massive_revolt")
    state = base_state.merge(
      "active" => "barbarian",
      "turn" => 0,
      "mode" => "hotseat",
      "revealed" => true,
      "selectedArea" => "allobroges",
      "selectedCard" => nil,
      "committed" => { "roman" => nil, "barbarian" => card },
      "hands" => { "roman" => [], "barbarian" => [card] }
    )
    state["units"]["allobroges"] = {
      "id" => "allobroges",
      "name" => "Allobroges",
      "type" => "barbarian",
      "owner" => "neutral",
      "location" => "allobroges",
      "home" => "allobroges",
      "step" => 0
    }
    state["units"]["vercingetorix"] = {
      "id" => "vercingetorix",
      "name" => "Vercingetorix",
      "type" => "leader",
      "owner" => "neutral",
      "location" => "offboard",
      "home" => "offboard",
      "step" => 0
    }
    session = GameSession.create!(data: state)

    result = GameRules::ActionPhase.new(session: session, state: session.data).event!(area_id: "allobroges")

    assert_equal "barbarian", result.dig("units", "allobroges", "owner")
    assert_equal "offboard", result.dig("units", "vercingetorix", "location")
    assert_not result["massiveRevoltPlayed"]
    assert_includes result["log"], "Turn 1: Massive Revolt is treated as a Minor Revolt."
    assert_match(/Minor Revolt resolved/, result["log"].first)
  end

  test "Roman Massive Revolt event does not unlock legions V and VI" do
    card = card_hash("event_4_massive_revolt")
    state = base_state.merge(
      "selectedCard" => card,
      "hands" => { "roman" => [card], "barbarian" => [] }
    )
    state["units"]["atuatuci"] = {
      "id" => "atuatuci",
      "name" => "Atuatuci",
      "type" => "barbarian",
      "owner" => "barbarian",
      "location" => "atuatuci",
      "home" => "atuatuci",
      "step" => 1
    }
    session = GameSession.create!(data: state)

    result = GameRules::ActionPhase.new(session: session, state: session.data).event!(unit_id: "atuatuci")

    assert_not result["massiveRevoltPlayed"]
  end

  private

  def neutral_allobroges
    {
      "id" => "allobroges",
      "name" => "Allobroges",
      "type" => "barbarian",
      "owner" => "neutral",
      "location" => "allobroges",
      "step" => 1
    }
  end

  def britannia_action_state
    card = card_hash("belgae")
    state = base_state.merge(
      "selectedCard" => card,
      "hands" => { "roman" => [card], "barbarian" => [] }
    )
    state["units"]["belgae"] = {
      "id" => "belgae",
      "name" => "Belgae",
      "type" => "barbarian",
      "owner" => "neutral",
      "location" => "belgae",
      "home" => "belgae",
      "strengths" => [2, 1],
      "step" => 0
    }
    state
  end

  def barbarian_unit(id:, name:, owner:, location:, home:, strengths:)
    {
      "id" => id,
      "name" => name,
      "type" => "barbarian",
      "owner" => owner,
      "location" => location,
      "home" => home,
      "initiative" => "C",
      "fire" => 2,
      "strengths" => strengths,
      "step" => 0
    }
  end

  def base_state
    {
      "active" => "roman",
      "supply" => 15,
      "mode" => "solitaire",
      "selectedCard" => card_hash("allobroges"),
      "hands" => { "roman" => [card_hash("allobroges")], "barbarian" => [] },
      "committed" => { "roman" => nil, "barbarian" => nil },
      "botDeck" => [],
      "discard" => [],
      "units" => {
        "legion_vii" => {
          "id" => "legion_vii",
          "name" => "Legion VII",
          "type" => "roman",
          "owner" => "roman",
          "location" => "allobroges",
          "step" => 0
        }
      },
      "log" => []
    }
  end

  def card_hash(key)
    Card.find_by!(key: key).game_data.stringify_keys
  end
end
