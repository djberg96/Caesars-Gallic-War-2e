module GameRules
  class MinorLeaders
    LEADER_BY_REGION = {
      "belgica" => "ambiorix",
      "celtae" => "dumnorix"
    }.freeze

    SCHEDULED_LEADERS = {
      4 => "dumnorix",
      5 => "ambiorix"
    }.freeze

    def initialize(state:)
      @state = state
    end

    def both_in_play?
      LEADER_BY_REGION.values.all? { |leader_id| in_play?(leader_id) }
    end

    def place_for_major_revolt!(area_ids)
      Array(area_ids).each do |area_id|
        area = Area.find_by(key: area_id)
        leader_id = LEADER_BY_REGION[area&.region]
        next if leader_id.blank? || in_play?(leader_id)

        return place!(leader_id, area)
      end
      nil
    end

    def place_scheduled!
      return unless @state["mode"] == "solitaire"

      leader_id = SCHEDULED_LEADERS[@state.fetch("turn", 0).to_i]
      return if leader_id.blank? || in_play?(leader_id)

      region = LEADER_BY_REGION.key(leader_id)
      area = Area.where(region: region).select { |candidate| eligible_start_area?(candidate) }.sample
      place!(leader_id, area) if area
    end

    private

    def in_play?(leader_id)
      location = units.dig(leader_id, "location")
      location.present? && !location.in?(["offboard", "eliminated"])
    end

    def eligible_start_area?(area)
      tribal_units(area).any? do |unit|
        unit["owner"].in?(["neutral", "roman"]) &&
          !unit["location"].in?([nil, "offboard", "eliminated"])
      end
    end

    def place!(leader_id, area)
      leader = units[leader_id]
      return unless leader && area

      leader["owner"] = "barbarian"
      leader["location"] = area.key
      leader["home"] = area.key
      leader["step"] = 0

      activated = tribal_units(area).select do |unit|
        !unit["location"].in?([nil, "offboard", "eliminated"])
      end
      activated.each do |unit|
        unit["owner"] = "barbarian"
        unit["location"] = area.key
      end

      {
        "leader" => leader,
        "area" => area,
        "activated" => activated
      }
    end

    def tribal_units(area)
      units.values.select do |unit|
        unit["type"] == "barbarian" && unit["home"] == area.key
      end
    end

    def units
      @state.fetch("units", {})
    end
  end
end
