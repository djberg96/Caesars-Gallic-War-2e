require "test_helper"

class GameRules::DealTest < ActiveSupport::TestCase
  setup do
    GameData::MapSeeder.seed!
    GameData::UnitTypeSeeder.seed!
    GameData::CardSeeder.seed!
  end

  test "does not redeal Massive Revolt after it resolves as a true Massive Revolt" do
    massive_revolt = card_hash("event_4_massive_revolt")
    state = deal_state.merge(
      "massiveRevoltPlayed" => true,
      "discard" => [massive_revolt]
    )
    session = GameSession.create!(data: state)

    result = GameRules::Deal.new(session: session, state: state).deal!

    dealt_ids = result.dig("hands", "roman").map { |card| card.fetch("id") } +
      result.fetch("botDeck").map { |card| card.fetch("id") }
    assert_not_includes dealt_ids, "event_4_massive_revolt"
    assert_empty result["discard"]
    assert_equal ["event_4_massive_revolt"], result["removedCards"].map { |card| card.fetch("id") }
    assert_equal "removed", session.reload.game_session_cards.find_by!(card: Card.find_by!(key: "event_4_massive_revolt")).location
  end

  test "redeals Massive Revolt when its earlier play resolved as a lesser revolt" do
    state = deal_state.merge("massiveRevoltPlayed" => false)
    session = GameSession.create!(data: state)

    result = GameRules::Deal.new(session: session, state: state).deal!

    dealt_ids = result.dig("hands", "roman").map { |card| card.fetch("id") } +
      result.fetch("botDeck").map { |card| card.fetch("id") }
    assert_includes dealt_ids, "event_4_massive_revolt"
    assert_empty result["removedCards"]
  end

  private

  def deal_state
    {
      "mode" => "solitaire",
      "turn" => 1,
      "active" => "roman",
      "supply" => 15,
      "vp" => 0,
      "hands" => { "roman" => [], "barbarian" => [] },
      "botDeck" => [],
      "discard" => [],
      "removedCards" => [],
      "committed" => { "roman" => nil, "barbarian" => nil },
      "units" => {},
      "log" => []
    }
  end

  def card_hash(key)
    Card.find_by!(key: key).game_data.stringify_keys
  end
end
