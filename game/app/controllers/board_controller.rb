class BoardController < ApplicationController
  ROMAN_HOMES = {
    legion_i: "roman_off_map",
    legion_v: "offboard",
    legion_vi: "offboard",
    legion_vii: "transalpine_gaul",
    legion_viii: "transalpine_gaul",
    legion_ix: "transalpine_gaul",
    legion_x: "transalpine_gaul",
    legion_xi: "transalpine_gaul",
    legion_xii: "transalpine_gaul",
    legion_xiii: "roman_off_map",
    legion_xiv: "roman_off_map",
    legion_xv: "roman_off_map"
  }.freeze

  LEADER_HOMES = {
    ambiorix: "offboard",
    dumnorix: "offboard",
    vercingetorix: "offboard"
  }.freeze

  GERMAN_HOMES = {
    ariovistus: "germania",
    german_marcomanni: "germania",
    german_tencteri: "germania",
    german_usipetes: "germania"
  }.freeze

  def index
    @game_data = {
      map: helpers.asset_path("Map/CGW_Map.jpg"),
      years: ["58 BC", "57 BC", "56 BC", "55 BC", "54 BC", "53 BC", "52 BC", "51 BC"],
      ai: ai_config,
      areas: areas,
      units: units,
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
    unit_svg_paths.each_with_object({}) do |path, specs|
      id = unit_id(path)
      specs[id] = unit_spec(id, path)
    end
  end

  def unit_spec(id, path)
    svg = File.read(path)
    logical_path = path.relative_path_from(images_path).to_s
    type = unit_type(path)

    {
      id: id,
      name: svg[/<title>(.*?)<\/title>/m, 1] || id.titleize,
      type: type,
      home: home_for(id, type),
      initiative: svg[/<g id="attributes".*?<text[^>]*>([A-D])<\/text>/m, 1] || "C",
      fire: (svg[/<g id="attributes".*?<rect[^>]*id="firepower".*?<text[^>]*>(\d+)<\/text>/m, 1] || 1).to_i,
      strengths: svg.scan(/<g id="strength".*?<\/g>/m).first.to_s.scan(/<text[^>]*>(\d+)<\/text>/).flatten.map(&:to_i),
      image: helpers.asset_path(logical_path)
    }
  end

  def unit_svg_paths
    images_path.glob("Blocks/{Romans,Barbarians}/**/*.svg").reject do |path|
      path.to_s.include?("/Misc/")
    end.sort
  end

  def unit_type(path)
    text = path.to_s
    return "roman" if text.include?("/Romans/")
    return "german" if text.include?("/Germania/")
    return "leader" if text.match?(/(Ambiorix|Dumnorix|Vercingetorix)\.svg\z/)

    "barbarian"
  end

  def home_for(id, type)
    return ROMAN_HOMES.fetch(id.to_sym) if type == "roman"
    return GERMAN_HOMES.fetch(id.to_sym) if type == "german"
    return LEADER_HOMES.fetch(id.to_sym) if type == "leader"

    areas.values.find { |area| area[:tribes].include?(id) || area[:alternate] == id }&.fetch(:id) || "offboard"
  end

  def images_path
    Rails.root.join("..", "images")
  end

  def unit_id(path)
    normalize(path.basename(".svg").to_s)
  end

  def normalize(value)
    value&.to_s&.underscore
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
