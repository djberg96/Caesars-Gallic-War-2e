module GameData
  class CardSeeder
    EVENTS = [
      "Baggage Train",
      "Minor Revolt",
      "Minor Revolt",
      "Major Revolt",
      "Massive Revolt"
    ].freeze

    class << self
      def seed!
        Card.transaction do
          Card.delete_all
          seed_area_cards!
          seed_event_cards!
        end
      end

      private

      def seed_area_cards!
        Area.order(:key).select(&:card_area?).each do |area|
          Card.create!(
            key: area.key,
            title: area.name,
            area: area,
            ap: card_ap(area),
            kind: "area"
          )
        end
      end

      def seed_event_cards!
        EVENTS.each_with_index do |title, index|
          Card.create!(
            key: "event_#{index}_#{title.parameterize(separator: "_")}",
            title: title,
            ap: 1,
            kind: "event"
          )
        end
      end

      def card_ap(area)
        return 3 if area.region == "germania"
        return 2 if area.region == "belgica"

        1
      end
    end
  end
end
