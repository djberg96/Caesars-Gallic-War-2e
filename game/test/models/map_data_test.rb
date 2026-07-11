require "test_helper"

class MapDataTest < ActiveSupport::TestCase
  setup do
    GameData::MapSeeder.seed!
  end

  test "imports map areas and directed borders" do
    assert_equal 32, Area.count
    assert_equal 152, Border.count

    allobroges = Area.find_by!(key: "allobroges")
    assert_equal ["allobroges"], allobroges.tribes
    assert_includes allobroges.game_data[:links], "helvetii"
    assert_equal "minor_river", allobroges.game_data[:borders]["helvetii"]
  end

  test "exposes minor river border capacity rules" do
    border = Border.find_by!(
      from_area: Area.find_by!(key: "allobroges"),
      to_area: Area.find_by!(key: "helvetii")
    )

    assert border.restricted?
    assert_equal 2, border.capacity
  end

  test "exposes black border capacity rules" do
    border = Border.find_by!(
      from_area: Area.find_by!(key: "allobroges"),
      to_area: Area.find_by!(key: "sequani")
    )

    assert border.restricted?
    assert_equal 4, border.capacity
  end
end
