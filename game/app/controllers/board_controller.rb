class BoardController < ApplicationController
  def index
    @game_data = {
      map: helpers.asset_path("Map/CGW_Map.jpg"),
      years: ["58 BC", "57 BC", "56 BC", "55 BC", "54 BC", "53 BC", "52 BC", "51 BC"],
      ai: ai_config,
      areas: areas,
      units: units,
      cards: cards,
      variable_areas: %w[atrebates carnutes esuvii menapi pictones atuatuci tarbelli tolosates]
    }
  end

  private

  def areas
    @areas ||= begin
      GameData::MapSeeder.seed! if Area.none?

      Area.includes(outgoing_borders: :to_area).order(:key).to_h do |area|
        [area.key, area.game_data]
      end
    end
  end

  def units
    @units ||= begin
      GameData::UnitTypeSeeder.seed! if UnitType.none?

      UnitType.order(:key).to_h do |unit_type|
        [unit_type.key, unit_type.game_data(helpers)]
      end
    end
  end

  def cards
    @cards ||= begin
      GameData::CardSeeder.seed! if Card.none?

      Card.includes(:area).order(:id).map(&:game_data)
    end
  end

  def ai_config
    path = Rails.root.join("config", "ai.yml")
    return { configured: false, model: nil } unless path.exist?

    config = YAML.load_file(path)
    env_config = config.fetch(Rails.env, config.fetch("default", {}))
    { configured: env_config["api_key"].present?, model: env_config["model"] }
  rescue Psych::Exception
    { configured: false, model: nil }
  end
end
