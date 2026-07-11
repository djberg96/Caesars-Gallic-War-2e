class BoardController < ApplicationController
  AREA_COORDINATES = {
    aedui: [62, 51],
    allobroges: [72, 62],
    andes: [30, 38],
    arverni: [53, 62],
    atrebates: [54, 18],
    atuatuci: [62, 29],
    bellovaci: [47, 25],
    belgae: [29, 7],
    bituriges: [49, 52],
    boii: [63, 63],
    cadurci: [42, 73],
    carnutes: [48, 43],
    esuvii: [40, 34],
    germania: [89, 10],
    helvetii: [84, 61],
    leuci: [84, 38],
    mandubii: [64, 41],
    mare_cantrabricum: [16, 61],
    mediomatrici: [84, 28],
    menapi: [69, 13],
    oceanus_britannicus: [31, 19],
    osismi: [14, 36],
    pictones: [29, 52],
    roman_off_map: [88, 77],
    santones: [38, 63],
    sequani: [78, 45],
    tarbelli: [29, 82],
    tolosates: [39, 87],
    transalpine_gaul: [74, 78],
    treveri: [77, 20],
    veneti: [23, 44],
    volcae: [57, 84]
  }.freeze

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
      areas: areas,
      units: units,
      variable_areas: %w[atrebates carnutes esuvii menapi pictones atuatuci tarbelli tolosates]
    }
  end

  private

  def areas
    map_points.index_by { |point| normalize(point.fetch("point")) }.transform_values do |point|
      id = normalize(point.fetch("point"))
      {
        id: id,
        name: area_name(point),
        x: AREA_COORDINATES.fetch(id.to_sym).first,
        y: AREA_COORDINATES.fetch(id.to_sym).last,
        region: point["region"],
        sea: point["region"].nil?,
        port: point["port"],
        fort: point["fort"],
        tribes: [id, normalize(point["second_tribe"])].compact,
        alternate: normalize(point["alternate_tribe"]),
        links: point.fetch("connections").map { |connection| normalize(connection.fetch("area")) }
      }
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

  def map_points
    @map_points ||= JSON.parse(Rails.root.join("..", "Misc", "map_points.json").read)
  end

  def images_path
    Rails.root.join("..", "images")
  end

  def area_name(point)
    parts = [point.fetch("point"), point["second_tribe"]].compact
    separator = point["alternate_tribe"].present? ? " / " : " + "
    if point["alternate_tribe"].present?
      [point.fetch("point"), point["alternate_tribe"]].map(&:titleize).join(separator)
    else
      parts.map(&:titleize).join(separator)
    end
  end

  def unit_id(path)
    normalize(path.basename(".svg").to_s)
  end

  def normalize(value)
    value&.to_s&.underscore
  end
end
