module GameData
  class UnitTypeSeeder
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

    class << self
      def seed!
        UnitType.transaction do
          UnitType.delete_all

          unit_svg_paths.each do |path|
            UnitType.create!(unit_attributes(path))
          end
        end
      end

      private

      def unit_attributes(path)
        key = unit_id(path)
        category = unit_category(path)
        svg = path.read

        {
          key: key,
          name: svg[/<title>(.*?)<\/title>/m, 1] || key.titleize,
          category: category,
          home: home_for(key, category),
          initiative: svg[/<g id="attributes".*?<text[^>]*>([A-D])<\/text>/m, 1] || "C",
          fire: (svg[/<g id="attributes".*?<rect[^>]*id="firepower".*?<text[^>]*>(\d+)<\/text>/m, 1] || 1).to_i,
          strengths: svg.scan(/<g id="strength".*?<\/g>/m).first.to_s.scan(/<text[^>]*>(\d+)<\/text>/).flatten.map(&:to_i),
          image_path: path.relative_path_from(images_path).to_s
        }
      end

      def unit_svg_paths
        images_path.glob("Blocks/{Romans,Barbarians}/**/*.svg").reject do |path|
          path.to_s.include?("/Misc/")
        end.sort
      end

      def unit_category(path)
        text = path.to_s
        return "roman" if text.include?("/Romans/")
        return "german" if text.include?("/Germania/")
        return "leader" if text.match?(/(Ambiorix|Dumnorix|Vercingetorix)\.svg\z/)

        "barbarian"
      end

      def home_for(key, category)
        return ROMAN_HOMES.fetch(key.to_sym) if category == "roman"
        return GERMAN_HOMES.fetch(key.to_sym) if category == "german"
        return LEADER_HOMES.fetch(key.to_sym) if category == "leader"

        Area.find_each.find do |area|
          area.tribes.include?(key) || area.alternate_tribe == key
        end&.key || "offboard"
      end

      def images_path
        Rails.root.join("..", "images")
      end

      def unit_id(path)
        path.basename(".svg").to_s.underscore
      end
    end
  end
end
