class GameSession < ApplicationRecord
  validates :data, presence: true
end
