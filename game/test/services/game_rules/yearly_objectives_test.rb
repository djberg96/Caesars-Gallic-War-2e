require "test_helper"

class GameRules::YearlyObjectivesTest < ActiveSupport::TestCase
  setup do
    GameData::MapSeeder.seed!
  end

  test "does nothing when the optional rule is disabled" do
    state = objective_state(turn: 0, enabled: false)

    result = GameRules::YearlyObjectives.new(state: state).score!

    assert_nil result
    assert_equal 0, state["vp"]
    assert_empty state["yearlyObjectiveHistory"]
  end

  test "awards gains before losses in the Ariovistus objectives" do
    state = objective_state(turn: 0)
    %w[sequani allobroges helvetii].each do |id|
      state["units"][id] = tribe(id, owner: "roman")
    end

    result = GameRules::YearlyObjectives.new(state: state).score!

    assert_equal 0, state["vp"]
    assert_equal 0, result["vp"]
    assert_equal %w[t1_roman_three t1_helvetii_survives], result["objectives"].map { |objective| objective["id"] }
    assert_equal result, state["yearlyObjectiveHistory"].sole
  end

  test "scores movement, combat, control, and wintering objectives in 55 BC" do
    state = objective_state(turn: 3)
    state["units"]["belgae"] = tribe("belgae", owner: "roman")
    state["units"]["german_tencteri"] = unit("german_tencteri", type: "german", owner: "barbarian", location: "menapi")
    state["yearlyObjectiveProgress"] = {
      "romanEnteredGermania" => true,
      "romanFoughtInGermania" => true,
      "romanEnteredBritannia" => true,
      "romanFoughtInBritannia" => true
    }

    result = GameRules::YearlyObjectives.new(state: state).score!

    assert_equal 1, state["vp"]
    assert_equal 1, result["vp"]
    assert_equal 4, result["objectives"].length
    assert_empty state["yearlyObjectiveProgress"]
  end

  test "scores regional control in the final year" do
    state = objective_state(turn: 7)
    state["units"]["atuatuci"] = tribe("atuatuci", owner: "roman")
    state["units"]["tarbelli"] = tribe("tarbelli", owner: "roman")
    state["units"]["aedui"] = tribe("aedui", owner: "roman")

    result = GameRules::YearlyObjectives.new(state: state).score!

    assert_equal 2, state["vp"]
    assert_equal ["t8_three_regions"], result["objectives"].map { |objective| objective["id"] }
  end

  private

  def objective_state(turn:, enabled: true)
    {
      "turn" => turn,
      "vp" => 0,
      "options" => { "yearlyObjectives" => enabled },
      "yearlyObjectiveProgress" => {},
      "yearlyObjectiveHistory" => [],
      "units" => {}
    }
  end

  def tribe(id, owner:)
    unit(id, type: "barbarian", owner: owner, location: id)
  end

  def unit(id, type:, owner:, location:)
    {
      "id" => id,
      "type" => type,
      "owner" => owner,
      "location" => location,
      "home" => id
    }
  end
end
