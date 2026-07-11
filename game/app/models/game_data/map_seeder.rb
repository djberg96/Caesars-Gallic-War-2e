module GameData
  class MapSeeder
    class << self
      def seed!
        Area.transaction do
          Border.delete_all
          Area.delete_all

          points.each do |point|
            create_area(point)
          end

          points.each do |point|
            create_borders(point)
          end
        end
      end

      private

      def points
        @points ||= JSON.parse(Rails.root.join("config", "data", "map_points.json").read)
      end

      def create_area(point)
        key = normalize(point.fetch("point"))
        x, y = GameData::AREA_COORDINATES.fetch(key.to_sym)
        fort = point["fort"] || {}

        Area.create!(
          key: key,
          name: area_name(point),
          x: x,
          y: y,
          region: point["region"],
          sea: point["region"].nil?,
          port: point["port"],
          fort_name: fort["name"],
          fort_level: fort["level"],
          special: point["special"],
          tribes: [key, normalize(point["second_tribe"])].compact,
          alternate_tribe: normalize(point["alternate_tribe"])
        )
      end

      def create_borders(point)
        from_area = Area.find_by!(key: normalize(point.fetch("point")))

        point.fetch("connections").each do |connection|
          Border.create!(
            from_area: from_area,
            to_area: Area.find_by!(key: normalize(connection.fetch("area"))),
            kind: connection.fetch("type")
          )
        end
      end

      def area_name(point)
        if point["alternate_tribe"].present?
          [point.fetch("point"), point["alternate_tribe"]].map(&:titleize).join(" / ")
        else
          [point.fetch("point"), point["second_tribe"]].compact.map(&:titleize).join(" + ")
        end
      end

      def normalize(value)
        value&.to_s&.underscore
      end
    end
  end
end
