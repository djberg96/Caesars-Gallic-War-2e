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
    assert_equal "barbarian", session.reload.game_units.joins(:unit_type).find_by!(unit_type: { key: "allobroges" }).owner
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
end
