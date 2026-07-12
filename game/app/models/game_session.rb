class GameSession < ApplicationRecord
  has_many :game_units, dependent: :destroy
  has_many :game_session_cards, dependent: :destroy

  validates :data, presence: true

  def sync_from_data!
    transaction do
      sync_header_from_data!
      sync_units_from_data!
      sync_cards_from_data!
    end
  end

  def sync_header_from_data!
    update!(
      turn_index: data.fetch("turn", 0).to_i,
      phase: data.fetch("phase", "Card Phase"),
      active_player: data.fetch("active", "roman"),
      supply: data.fetch("supply", 15).to_i,
      vp: data.fetch("vp", 0).to_i,
      mode: data.fetch("mode", "hotseat"),
      revealed: boolean_value(data.fetch("revealed", false)),
      dice_rolled_this_turn: boolean_value(data.fetch("diceRolledThisTurn", false)),
      bot_neutral_activations: data.fetch("botNeutralActivations", 0).to_i
    )
  end

  def sync_units_from_data!
    units = data.fetch("units", {})

    game_units.delete_all
    units.each do |unit_key, attributes|
      game_units.create!(
        unit_type: UnitType.find_by!(key: unit_key),
        area: Area.find_by(key: attributes.fetch("location")),
        location: attributes.fetch("location"),
        owner: attributes.fetch("owner"),
        step: attributes.fetch("step", 0)
      )
    end
  end

  def sync_cards_from_data!
    game_session_cards.delete_all
    sync_card_list(data.dig("hands", "roman"), "roman_hand")
    sync_card_list(data.dig("hands", "barbarian"), "barbarian_hand")
    sync_card_list(data["botDeck"], "bot_deck")
    sync_card_list(data["discard"], "discard")
    sync_committed_card(data.dig("committed", "roman"), "committed_roman")
    sync_committed_card(data.dig("committed", "barbarian"), "committed_barbarian")
  end

  private

  def boolean_value(value)
    ActiveModel::Type::Boolean.new.cast(value)
  end

  def sync_card_list(cards, location)
    Array(cards).each_with_index do |card_data, position|
      sync_card(card_data, location, position)
    end
  end

  def sync_committed_card(card_data, location)
    return if card_data.blank?

    existing = game_session_cards.find_by(card: Card.find_by!(key: card_data.fetch("id")))
    if existing
      existing.update!(location: location, position: 0)
    else
      sync_card(card_data, location, 0)
    end
  end

  def sync_card(card_data, location, position)
    return if card_data.blank?

    game_session_cards.create!(
      card: Card.find_by!(key: card_data.fetch("id")),
      location: location,
      position: position
    )
  end
end
