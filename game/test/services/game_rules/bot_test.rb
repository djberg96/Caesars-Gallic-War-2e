require "test_helper"

class GameRules::BotTest < ActiveSupport::TestCase
  setup do
    GameData::MapSeeder.seed!
    GameData::UnitTypeSeeder.seed!
    GameData::CardSeeder.seed!
  end

  test "draws a bot area card and activates neutral tribes" do
    session = GameSession.create!(data: bot_state(bot_deck: [card_hash("allobroges")]))
    session.sync_from_data!

    result = GameRules::Bot.new(session: session, state: session.data).draw!

    assert_equal "barbarian", result.dig("units", "allobroges", "owner")
    assert_equal 1, result["botNeutralActivations"]
    assert_empty result["botDeck"]
    assert_equal ["allobroges"], result["discard"].map { |card| card.fetch("id") }
    assert_equal ["allobroges"], result.dig("neutralActivationCards", "barbarian").map { |card| card.fetch("id") }
    assert_includes result["log"], "Allobroges becomes a Barbarian ally."
    assert_equal "barbarian", session.reload.game_units.joins(:unit_type).find_by!(unit_type: { key: "allobroges" }).owner
  end

  test "second bot neutral tribe activation does not start movement" do
    state = bot_state(bot_deck: [card_hash("allobroges")]).merge("botNeutralActivations" => 1)
    state["neutralActivationCards"] = { "roman" => [], "barbarian" => [card_hash("andes")] }
    session = GameSession.create!(data: state)
    session.sync_from_data!

    result = GameRules::Bot.new(session: session, state: session.data).draw!

    assert_equal "barbarian", result.dig("units", "allobroges", "owner")
    assert_equal 2, result["botNeutralActivations"]
    assert_nil result["movement"]
    assert_not_equal "movement", result["currentAction"]
    assert_equal ["andes", "allobroges"], result.dig("neutralActivationCards", "barbarian").map { |card| card.fetch("id") }
    assert_no_match "moves", result["log"].join(" ")
  end

  test "draws a bot area card and performs political action after neutral activations are spent" do
    state = bot_state(bot_deck: [card_hash("allobroges")]).merge("botNeutralActivations" => 2)
    state["units"]["allobroges"]["owner"] = "roman"
    session = GameSession.create!(data: state)

    result = GameRules::Bot.new(session: session, state: session.data, roll: 1).draw!

    assert_equal "barbarian", result.dig("units", "allobroges", "owner")
    assert result["diceRolledThisTurn"]
    assert_match "political action succeeds", result["log"].join(" ")
  end

  test "a successful bot political action attacks Romans occupying the tribe's home" do
    state = bot_state(bot_deck: [card_hash("allobroges")]).merge("botNeutralActivations" => 2)
    state["units"]["allobroges"]["owner"] = "roman"
    state["units"]["legion_vii"] = {
      "id" => "legion_vii",
      "name" => "Legion VII",
      "type" => "roman",
      "owner" => "roman",
      "location" => "allobroges",
      "home" => "roman_off_map",
      "step" => 0,
      "strengths" => [4, 3, 2, 1],
      "initiative" => "A",
      "fire" => 2
    }
    session = GameSession.create!(data: state)

    result = GameRules::Bot.new(session: session, state: session.data, roll: 1).draw!

    assert_equal "barbarian", result.dig("units", "allobroges", "owner")
    assert_equal "allobroges", result.dig("units", "allobroges", "location")
    assert_equal "allobroges", result.dig("battle", "area")
    assert_equal "barbarian", result.dig("battle", "attacker")
    assert_equal "roman", result.dig("battle", "defender")
    assert_includes result.dig("battle", "attackers"), "allobroges"
    assert_includes result.dig("battle", "defenders"), "legion_vii"
  end

  test "uses a political action instead of treating an unplayable area card as a revolt" do
    state = bot_state(bot_deck: [card_hash("leuci")]).merge("botNeutralActivations" => 2)
    state["units"] = {
      "leuci" => barbarian_unit("leuci", "Leuci", "leuci", "barbarian", [2, 1], fire: 1),
      "allobroges" => barbarian_unit("allobroges", "Allobroges", "allobroges", "neutral", [2, 1], fire: 1)
    }
    session = GameSession.create!(data: state)

    result = GameRules::Bot.new(session: session, state: session.data, roll: 1, target: "allobroges").draw!

    assert_equal "barbarian", result.dig("units", "allobroges", "owner")
    assert result["diceRolledThisTurn"]
    assert_match "fallback political action", result["log"].join(" ")
    assert_match "political action succeeds", result["log"].join(" ")
    assert_no_match "Barbarian activates Allobroges", result["log"].join(" ")
  end

  test "Germania attacks two areas with two eligible units per area" do
    state = bot_state(bot_deck: [card_hash("germania")])
    state["units"] = {
      "ariovistus" => german_unit("ariovistus", "Ariovistus"),
      "german_marcomanni" => german_unit("german_marcomanni", "German - Marcomanni"),
      "german_tencteri" => german_unit("german_tencteri", "German - Tencteri"),
      "german_usipetes" => german_unit("german_usipetes", "German - Usipetes"),
      "leuci" => barbarian_unit("leuci", "Leuci", "leuci", "neutral", [2, 1], fire: 1).merge("initiative" => "A"),
      "mediomatrici" => barbarian_unit("mediomatrici", "Mediomatrici", "mediomatrici", "neutral", [2, 1], fire: 1).merge("initiative" => "A")
    }
    session = GameSession.create!(data: state)

    result = GameRules::Bot.new(session: session, state: session.data, roll: 6).draw!

    german_locations = %w[ariovistus german_marcomanni german_tencteri german_usipetes]
      .map { |id| result.dig("units", id, "location") }
    assert_equal ["leuci", "leuci", "mediomatrici", "mediomatrici"].sort, german_locations.sort
    assert_equal 1, result.fetch("pendingBattleEntries").length
    assert result["battle"].present?
    assert_equal "barbarian", result.dig("battle", "attacker")
  end

  test "Ariovistus subdues neutral Gallic units before a bot battle" do
    state = bot_state(bot_deck: [card_hash("germania")])
    state["units"] = {
      "ariovistus" => german_unit("ariovistus", "Ariovistus"),
      "german_marcomanni" => german_unit("german_marcomanni", "German - Marcomanni"),
      "leuci" => barbarian_unit("leuci", "Leuci", "leuci", "neutral", [2, 1], fire: 1)
    }
    session = GameSession.create!(data: state)

    result = GameRules::Bot.new(session: session, state: session.data, roll: 2).draw!

    assert_equal "barbarian", result.dig("units", "leuci", "owner")
    assert_nil result["battle"]
    assert result["diceRolledThisTurn"]
    assert_match "Ariovistus special ability: rolled 2 for Leuci", result["log"].join(" ")
    assert_match "Leuci joins the Barbarian attacking force", result["log"].join(" ")
  end

  test "Ariovistus resolves each neutral Gallic unit separately" do
    state = bot_state(bot_deck: [])
    state["units"] = {
      "ariovistus" => german_unit("ariovistus", "Ariovistus"),
      "german_marcomanni" => german_unit("german_marcomanni", "German - Marcomanni"),
      "leuci" => barbarian_unit("leuci", "Leuci", "leuci", "neutral", [2, 1], fire: 1),
      "mediomatrici" => barbarian_unit("mediomatrici", "Mediomatrici", "mediomatrici", "neutral", [2, 1], fire: 1).merge(
        "location" => "leuci"
      )
    }
    session = GameSession.create!(data: state)
    bot = GameRules::Bot.new(session: session, state: session.data, rolls: [1, 5])

    assert bot.send(:bot_move_from_germania, Area.find_by!(key: "germania"), resolve_battle: false)
    result = bot.send(:persist!)

    assert_equal "barbarian", result.dig("units", "leuci", "owner")
    assert_equal "roman", result.dig("units", "mediomatrici", "owner")
    assert_match "rolled 1 for Leuci", result["log"].join(" ")
    assert_match "rolled 5 for Mediomatrici", result["log"].join(" ")
    assert_match "Mediomatrici resists and joins the Roman defense", result["log"].join(" ")
    assert_equal "barbarian", result.dig("pendingBattleEntries", "leuci", "attacker")
  end

  test "draws a revolt event and activates its target" do
    session = GameSession.create!(data: bot_state(bot_deck: [card_hash("event_1_minor_revolt")]))
    session.sync_from_data!

    result = GameRules::Bot.new(session: session, state: session.data, target: "allobroges").draw!

    assert_equal(
      { "cardId" => "event_1_minor_revolt", "kind" => "event" },
      result["lastBotAction"]
    )
    assert_equal "barbarian", result.dig("units", "allobroges", "owner")
    assert_empty result["botDeck"]
    assert_equal ["event_1_minor_revolt"], result["discard"].map { |card| card.fetch("id") }
    assert_includes result["log"], "Barbarian activates Allobroges."
  end

  test "minor revolt attacks Roman occupants in the revolting tribe's home area" do
    state = bot_state(bot_deck: [card_hash("event_1_minor_revolt")])
    state["units"] = {
      "sequani" => barbarian_unit("sequani", "Sequani", "sequani", "roman", [4, 3, 2, 1], fire: 2).merge(
        "initiative" => "B"
      ),
      "allobroges" => barbarian_unit("allobroges", "Allobroges", "allobroges", "roman", [2, 1], fire: 1).merge(
        "location" => "sequani"
      ),
      "legion_xii" => {
        "id" => "legion_xii",
        "name" => "Legion XII",
        "type" => "roman",
        "owner" => "roman",
        "location" => "sequani",
        "home" => "transalpine_gaul",
        "step" => 0,
        "strengths" => [4, 3, 2, 1],
        "initiative" => "A",
        "fire" => 2
      }
    }
    session = GameSession.create!(data: state)

    result = GameRules::Bot.new(session: session, state: session.data, target: "sequani").draw!

    assert_equal "barbarian", result.dig("units", "sequani", "owner")
    assert_equal "sequani", result.dig("battle", "area")
    assert_equal "barbarian", result.dig("battle", "attacker")
    assert_equal "roman", result.dig("battle", "defender")
    assert_equal ["sequani"], result.dig("battle", "attackers")
    assert_equal ["allobroges", "legion_xii"], result.dig("battle", "defenders").sort
    assert_match "Battle board opened for Sequani", result["log"].join(" ")
  end

  test "records Baggage Train as movement when Germans can attack" do
    state = bot_state(bot_deck: [card_hash("event_0_baggage_train")])
    state["units"] = {
      "ariovistus" => german_unit("ariovistus", "Ariovistus"),
      "german_marcomanni" => german_unit("german_marcomanni", "German - Marcomanni"),
      "leuci" => barbarian_unit("leuci", "Leuci", "leuci", "neutral", [2, 1], fire: 1)
    }
    session = GameSession.create!(data: state)

    result = GameRules::Bot.new(session: session, state: session.data).draw!

    assert_equal(
      { "cardId" => "event_0_baggage_train", "kind" => "movement" },
      result["lastBotAction"]
    )
    assert_equal ["leuci", "leuci"], %w[ariovistus german_marcomanni].map { |id| result.dig("units", id, "location") }
    assert_equal 15, result["supply"]
  end

  test "records Baggage Train as an event when no Germans can attack" do
    state = bot_state(bot_deck: [card_hash("event_0_baggage_train")]).merge("supply" => 15)
    session = GameSession.create!(data: state)

    result = GameRules::Bot.new(session: session, state: session.data).draw!

    assert_equal(
      { "cardId" => "event_0_baggage_train", "kind" => "event" },
      result["lastBotAction"]
    )
    assert_equal 13, result["supply"]
  end

  test "major revolt takes control of Roman allied tribes and returns every home-area tribe" do
    state = bot_state(bot_deck: [card_hash("event_3_major_revolt")])
    state["units"] = {
      "bellovaci" => barbarian_unit("bellovaci", "Bellovaci", "bellovaci", "roman", [4, 3, 2, 1], fire: 2).merge(
        "location" => "atuatuci",
        "step" => 1
      ),
      "caletes" => barbarian_unit("caletes", "Caletes", "bellovaci", "roman", [3, 2, 1], fire: 1).merge(
        "location" => "mandubii"
      ),
      "mandubii" => barbarian_unit("mandubii", "Mandubii", "mandubii", "neutral", [3, 2, 1], fire: 2)
    }
    session = GameSession.create!(data: state)

    result = GameRules::Bot.new(session: session, state: session.data, target: "bellovaci").draw!

    assert_equal "barbarian", result.dig("units", "bellovaci", "owner")
    assert_equal "barbarian", result.dig("units", "caletes", "owner")
    assert_equal "bellovaci", result.dig("units", "bellovaci", "location")
    assert_equal "bellovaci", result.dig("units", "caletes", "location")
    assert_equal 1, result.dig("units", "bellovaci", "step")
    assert_match "Barbarian activates Bellovaci + Caletes", result["log"].join(" ")
  end

  test "records the bot entry border and prevents the defender retreating through it" do
    state = bot_state(bot_deck: [card_hash("boii")])
    state["units"] = {
      "volcae" => barbarian_unit("volcae", "Volcae", "volcae", "roman", [2, 1], fire: 1),
      "boii" => barbarian_unit("boii", "Boii", "boii", "barbarian", [3, 2, 1], fire: 2),
      "helvii" => barbarian_unit("helvii", "Helvii", "boii", "barbarian", [2, 1], fire: 1),
      "tolosates" => barbarian_unit("tolosates", "Tolosates", "tolosates", "neutral", [2, 1], fire: 1),
      "cadurci" => barbarian_unit("cadurci", "Cadurci", "cadurci", "neutral", [2, 1], fire: 1),
      "arverni" => barbarian_unit("arverni", "Arverni", "arverni", "neutral", [2, 1], fire: 1)
    }
    session = GameSession.create!(data: state)

    result = GameRules::Bot.new(session: session, state: session.data).draw!

    assert_equal "barbarian", result.dig("battle", "attacker")
    assert_equal "roman", result.dig("battle", "defender")
    assert_equal "boii", result.dig("battle", "mainOrigin")
    assert_equal({ "boii" => "boii", "helvii" => "boii" }, result.dig("battle", "entries"))
    assert_equal "volcae", result.dig("battle", "activeUnit")

    error = assert_raises(GameRules::Battle::InvalidAction) do
      GameRules::Battle.new(session: session, state: result).act!(
        action: "retreat",
        unit_id: "volcae",
        target: "boii"
      )
    end
    assert_match "enemy units entered Volcae from there", error.message

    result = GameRules::Battle.new(session: session, state: result).act!(
      action: "retreat",
      unit_id: "volcae"
    )
    assert_equal "transalpine_gaul", result.dig("units", "volcae", "location")
  end

  test "a bot attack into the Alps preserves attacker and origin data for Roman defense and retreat" do
    state = bot_state(bot_deck: [card_hash("leuci")])
    state["units"] = {
      "legion_viii" => {
        "id" => "legion_viii",
        "name" => "Legion VIII",
        "type" => "roman",
        "owner" => "roman",
        "location" => "helvetii",
        "home" => "transalpine_gaul",
        "step" => 0,
        "strengths" => [4, 3, 2, 1],
        "initiative" => "A",
        "fire" => 0
      },
      "leuci" => barbarian_unit("leuci", "Leuci", "leuci", "barbarian", [4, 3, 2, 1], fire: 2)
    }
    session = GameSession.create!(data: state)

    result = GameRules::Bot.new(session: session, state: session.data).draw!

    assert_equal "barbarian", result.dig("battle", "attacker")
    assert_equal "roman", result.dig("battle", "defender")
    assert_equal "leuci", result.dig("battle", "mainOrigin")
    assert_equal "leuci", result.dig("battle", "entries", "leuci")

    error = assert_raises(GameRules::Battle::InvalidAction) do
      GameRules::Battle.new(session: session, state: result).act!(
        action: "retreat",
        unit_id: "legion_viii",
        target: "leuci"
      )
    end
    assert_match "enemy units entered Helvetii from there", error.message

    result = GameRules::Battle.new(session: session, state: result, rolls: [1, 1, 6, 6]).act!(
      action: "pass",
      unit_id: "legion_viii"
    )
    assert_equal 1, result.dig("units", "legion_viii", "step")
    leuci_fire = result.dig("battle", "actionResults").find { |entry| entry["unitId"] == "leuci" }
    assert_equal 2, leuci_fire["hits"]
    assert_equal 1, leuci_fire["appliedHits"]

    result = GameRules::Battle.new(session: session, state: result).act!(
      action: "acknowledge_roll",
      unit_id: "leuci"
    )

    result = GameRules::Battle.new(session: session, state: result).act!(
      action: "retreat",
      unit_id: "legion_viii",
      target: "transalpine_gaul"
    )
    assert_nil result["battle"]
    assert_equal "transalpine_gaul", result.dig("units", "legion_viii", "location")
    assert_equal "helvetii", result.dig("units", "leuci", "location")
    assert_match "Barbarian holds Helvetii after battle", result["log"].join(" ")
  end

  test "a neutral tribe joins the Roman player and fights when the bot enters its area" do
    state = bot_state(bot_deck: [card_hash("boii")])
    state["units"] = {
      "boii" => barbarian_unit("boii", "Boii", "boii", "barbarian", [3, 2, 1], fire: 2),
      "volcae" => barbarian_unit("volcae", "Volcae", "volcae", "neutral", [2, 1], fire: 1)
    }
    session = GameSession.create!(data: state)

    result = GameRules::Bot.new(session: session, state: session.data).draw!

    assert_equal "roman", result.dig("units", "volcae", "owner")
    assert_equal "volcae", result.dig("battle", "area")
    assert_equal "barbarian", result.dig("battle", "attacker")
    assert_equal ["boii"], result.dig("battle", "attackers")
    assert_equal ["volcae"], result.dig("battle", "defenders")
    assert_equal "boii", result.dig("battle", "entries", "boii")
    assert_match "Volcae joins the Roman player", result["log"].join(" ")
    assert_no_match "No battles to resolve", result["log"].join(" ")
  end

  test "keeps entry data for multiple bot battles created by one event" do
    state = bot_state(bot_deck: [])
    state["units"] = {
      "mandubii" => barbarian_unit("mandubii", "Mandubii", "mandubii", "barbarian", [2, 1], fire: 1),
      "atuatuci" => barbarian_unit("atuatuci", "Atuatuci", "atuatuci", "barbarian", [2, 1], fire: 1),
      "carnutes" => barbarian_unit("carnutes", "Carnutes", "carnutes", "neutral", [2, 1], fire: 1),
      "atrebates" => barbarian_unit("atrebates", "Atrebates", "atrebates", "neutral", [2, 1], fire: 1)
    }
    session = GameSession.create!(data: state)
    bot = GameRules::Bot.new(session: session, state: session.data)

    assert bot.send(:bot_move_from, "mandubii", resolve_battle: false)
    assert bot.send(:bot_move_from, "atuatuci", resolve_battle: false)
    result = bot.send(:resolve_next_bot_battle!)

    assert_equal 2, result.fetch("pendingBattleEntries").length + 1
    assert_equal "barbarian", result.dig("battle", "attacker")
    assert_equal "roman", result.dig("battle", "defender")
    remaining = result.fetch("pendingBattleEntries").values.first
    assert_equal "barbarian", remaining.fetch("attacker")
    assert_equal 1, remaining.fetch("entries").length

    remaining_area = result.fetch("pendingBattleEntries").keys.sole
    active_id = result.dig("battle", "activeUnit")
    result = GameRules::Battle.new(session: session, state: result, rolls: [1, 1]).act!(
      action: "fire",
      unit_id: active_id
    )
    result = GameRules::Battle.new(session: session, state: result).act!(
      action: "acknowledge_roll",
      unit_id: active_id
    )
    result = GameRules::Battle.new(session: session, state: result).act!(action: "regroup")

    assert_equal remaining_area, result.dig("battle", "area")
    assert_empty result.fetch("pendingBattleEntries")
  end

  test "treats turn one massive revolt as a major revolt in solitaire" do
    state = bot_state(bot_deck: [card_hash("event_4_massive_revolt")])
    state["units"]["vercingetorix"] = {
      "id" => "vercingetorix",
      "name" => "Vercingetorix",
      "type" => "leader",
      "owner" => "neutral",
      "location" => "offboard",
      "home" => "offboard",
      "step" => 0,
      "strengths" => [4]
    }
    state["units"]["boii"] = {
      "id" => "boii",
      "name" => "Boii",
      "type" => "barbarian",
      "owner" => "neutral",
      "location" => "boii",
      "home" => "boii",
      "step" => 0,
      "strengths" => [3]
    }
    session = GameSession.create!(data: state)

    result = GameRules::Bot.new(session: session, state: session.data, target: "allobroges").draw!

    assert_equal "barbarian", result.dig("units", "allobroges", "owner")
    assert_equal "allobroges", result.dig("units", "allobroges", "location")
    assert_equal "barbarian", result.dig("units", "boii", "owner")
    assert_equal "offboard", result.dig("units", "vercingetorix", "location")
    assert_not result["massiveRevoltPlayed"]
    assert_includes result["log"], "Turn 1: Massive Revolt is treated as a Major Revolt."
    assert_match(/Bot revolt areas: Allobroges, Boii/, result["log"].join(" "))
  end

  test "Massive Revolt unlocks legions V and VI only when resolved as Massive" do
    state = bot_state(bot_deck: [card_hash("event_4_massive_revolt")])
    state["turn"] = 5
    state["units"]["vercingetorix"] = {
      "id" => "vercingetorix",
      "name" => "Vercingetorix",
      "type" => "leader",
      "owner" => "neutral",
      "location" => "offboard",
      "home" => "offboard",
      "step" => 0,
      "strengths" => [4]
    }
    session = GameSession.create!(data: state)

    result = GameRules::Bot.new(session: session, state: session.data, target: "allobroges").draw!

    assert result["massiveRevoltPlayed"]
    assert_equal "allobroges", result.dig("units", "vercingetorix", "location")
  end

  private

  def bot_state(bot_deck:)
    {
      "mode" => "solitaire",
      "active" => "roman",
      "turn" => 0,
      "supply" => 15,
      "vp" => 0,
      "botNeutralActivations" => 0,
      "botDeck" => bot_deck,
      "discard" => [],
      "hands" => { "roman" => [], "barbarian" => [] },
      "committed" => { "roman" => nil, "barbarian" => nil },
      "units" => {
        "allobroges" => {
          "id" => "allobroges",
          "name" => "Allobroges",
          "type" => "barbarian",
          "owner" => "neutral",
          "location" => "allobroges",
          "home" => "allobroges",
          "step" => 0,
          "strengths" => [1],
          "initiative" => "D",
          "fire" => 1
        }
      },
      "log" => []
    }
  end

  def card_hash(key)
    Card.find_by!(key: key).game_data.stringify_keys
  end

  def barbarian_unit(id, name, home, owner, strengths, fire:)
    {
      "id" => id,
      "name" => name,
      "type" => "barbarian",
      "owner" => owner,
      "location" => home,
      "home" => home,
      "step" => 0,
      "strengths" => strengths,
      "initiative" => "C",
      "fire" => fire
    }
  end

  def german_unit(id, name)
    barbarian_unit(id, name, "germania", "barbarian", [3, 2, 1], fire: 2).merge("type" => "german")
  end
end
