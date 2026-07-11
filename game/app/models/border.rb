class Border < ApplicationRecord
  CAPACITIES = {
    "regular" => 4,
    "naval" => nil,
    "black" => 4,
    "minor_river" => 2
  }.freeze

  belongs_to :from_area, class_name: "Area", inverse_of: :outgoing_borders
  belongs_to :to_area, class_name: "Area"

  validates :kind, presence: true
  validates :from_area_id, uniqueness: { scope: :to_area_id }

  def capacity
    CAPACITIES.fetch(kind, nil)
  end

  def restricted?
    capacity.present?
  end
end
