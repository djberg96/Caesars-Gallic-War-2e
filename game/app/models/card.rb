class Card < ApplicationRecord
  belongs_to :area, optional: true

  validates :key, presence: true, uniqueness: true
  validates :title, :kind, :ap, presence: true

  def game_data
    {
      id: key,
      title: title,
      area: area&.key,
      ap: ap,
      type: kind
    }
  end
end
