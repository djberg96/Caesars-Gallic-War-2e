class GameUnit < ApplicationRecord
  belongs_to :game_session
  belongs_to :unit_type
  belongs_to :area, optional: true

  validates :location, :owner, presence: true
  validates :unit_type_id, uniqueness: { scope: :game_session_id }
end
