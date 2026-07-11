class Area < ApplicationRecord
  has_many :outgoing_borders,
           -> { includes(:to_area) },
           class_name: "Border",
           foreign_key: :from_area_id,
           inverse_of: :from_area,
           dependent: :destroy

  validates :key, presence: true, uniqueness: true
  validates :name, :x, :y, presence: true

  def game_data
    {
      id: key,
      name: name,
      x: x,
      y: y,
      region: region,
      sea: sea,
      port: port,
      fort: fort,
      tribes: tribes,
      alternate: alternate_tribe,
      links: sorted_outgoing_borders.map { |border| border.to_area.key },
      borders: sorted_outgoing_borders.to_h { |border| [border.to_area.key, border.kind] }
    }
  end

  private

  def sorted_outgoing_borders
    outgoing_borders.sort_by { |border| border.to_area.key }
  end

  def fort
    return nil if fort_name.blank?

    { name: fort_name, level: fort_level }
  end
end
