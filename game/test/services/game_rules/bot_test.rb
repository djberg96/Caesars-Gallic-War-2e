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
    assert_includes result["log"], "Barbarian places Allobroges in the neutral tribe activation area."
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

  test "draws a revolt event and activates its target" do
    session = GameSession.create!(data: bot_state(bot_deck: [card_hash("event_1_minor_revolt")]))
    session.sync_from_data!

    result = GameRules::Bot.new(session: session, state: session.data, target: "allobroges").draw!

    assert_equal "barbarian", result.dig("units", "allobroges", "owner")
    assert_empty result["botDeck"]
    assert_equal ["event_1_minor_revolt"], result["discard"].map { |card| card.fetch("id") }
    assert_includes result["log"], "Barbarian activates Allobroges."
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
    assert_includes result["log"], "Turn 1: Massive Revolt is treated as a Major Revolt."
    assert_match(/Bot revolt areas: Allobroges, Boii/, result["log"].join(" "))
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
end
