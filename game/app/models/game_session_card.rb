class GameSessionCard < ApplicationRecord
  belongs_to :game_session
  belongs_to :card

  validates :location, :position, presence: true
  validates :card_id, uniqueness: { scope: :game_session_id }
end
