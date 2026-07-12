class UnitType < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :name, :category, :home, :initiative, :fire, :image_path, presence: true

  def game_data(view_context)
    {
      id: key,
      name: name,
      type: category,
      home: home,
      initiative: initiative,
      fire: fire,
      strengths: strengths,
      image: view_context.asset_path(image_path)
    }
  end
end
