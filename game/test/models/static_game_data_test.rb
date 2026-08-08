require "test_helper"

class StaticGameDataTest < ActiveSupport::TestCase
  setup do
    GameData::MapSeeder.seed!
    GameData::UnitTypeSeeder.seed!
    GameData::CardSeeder.seed!
  end

  test "imports unit types from block artwork" do
    assert_equal 64, UnitType.count

    legion = UnitType.find_by!(key: "legion_x")
    assert_equal "Legion X", legion.name
    assert_equal "roman", legion.category
    assert_equal "transalpine_gaul", legion.home
    assert_equal "A", legion.initiative
    assert_equal 3, legion.fire
    assert_equal [4, 3, 2, 1], legion.strengths
  end

  test "imports area and event cards" do
    assert_equal 33, Card.count

    allobroges = Card.find_by!(key: "allobroges")
    assert_equal "area", allobroges.kind
    assert_equal 2, allobroges.ap
    assert_equal "allobroges", allobroges.area.key
    assert_equal 2, Card.find_by!(key: "belgae").ap
    assert_equal 3, Card.find_by!(key: "helvetii").ap
    assert_equal 3, Card.find_by!(key: "bellovaci").ap
    assert_equal 2, Card.find_by!(key: "arverni").ap
    assert_equal 1, Card.find_by!(key: "tarbelli").ap
    assert_equal 2, Area.find_by!(key: "sequani").card_value
    assert_nil Area.find_by!(key: "transalpine_gaul").card_value

    massive_revolt = Card.find_by!(key: "event_4_massive_revolt")
    assert_equal "Massive Revolt", massive_revolt.title
    assert_equal "event", massive_revolt.kind
    assert_nil massive_revolt.area
  end

  test "provides a history for every unit type" do
    assert_equal UnitType.order(:key).pluck(:key), GameData::UnitHistories::HISTORIES.keys.sort

    UnitType.find_each do |unit_type|
      assert_predicate GameData::UnitHistories.fetch(unit_type), :present?, "Missing history for #{unit_type.key}"
    end
  end
end
