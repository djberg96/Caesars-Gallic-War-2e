require "test_helper"
require "tmpdir"

class GameRules::PostGameReportTest < ActiveSupport::TestCase
  setup do
    GameData::MapSeeder.seed!
    GameData::UnitTypeSeeder.seed!
  end

  test "records a private chronicle and captures the completed year only when enabled" do
    disabled = report_state.merge("options" => { "postGameReport" => false })
    GameRules::PostGameReport.record!(disabled, "This should not be retained.")
    GameRules::PostGameReport.capture_year!(disabled, controlled_tribes: 4)

    assert_nil disabled["campaignLog"]
    assert_nil disabled["campaignSnapshots"]

    state = report_state
    GameRules::PostGameReport.record!(state, "Roman wins the battle in Sequani.")
    GameRules::PostGameReport.capture_year!(state, controlled_tribes: 6)

    assert_equal "Roman wins the battle in Sequani.", state.dig("campaignLog", 0, "message")
    assert_equal "51 BC", state.dig("campaignSnapshots", 0, "year")
    assert_equal 6, state.dig("campaignSnapshots", 0, "controlledTribes")
    assert_equal 1, state.dig("campaignSnapshots", 0, "fieldLegions")
    assert_equal 1, state.dig("campaignSnapshots", 0, "romanAllies")
  end

  test "writes a self-contained narrative HTML report for a completed campaign" do
    state = report_state
    state["campaignLog"] = [
      { "turn" => 0, "year" => "58 BC", "message" => "Roman wins the battle in Helvetii." },
      { "turn" => 7, "year" => "51 BC", "message" => "Campaign complete: Major Roman Victory with 112 Roman VP." },
      { "turn" => 7, "year" => "51 BC", "message" => "A message with <script>alert('Gaul')</script>." }
    ]
    state["campaignSnapshots"] = 8.times.map do |turn|
      {
        "turn" => turn,
        "year" => GameRules::PostGameReport::YEARS.fetch(turn),
        "vp" => (turn + 1) * 14,
        "vpGained" => 14,
        "supply" => 15 - turn,
        "controlledTribes" => turn + 2,
        "romanAllies" => 1,
        "fieldLegions" => 1,
        "eliminatedLegions" => 0,
        "romanForces" => turn == 7 ? [{ "name" => "Legion VII", "type" => "roman", "location" => "sequani", "strength" => 4 }] : [],
        "highlights" => ["Rome secured a foothold in turn #{turn + 1}."]
      }
    end
    session = GameSession.create!(data: { "phase" => "Game Over" })
    generated_at = Time.zone.local(2026, 8, 7, 20, 15, 0)

    Dir.mktmpdir do |directory|
      metadata = GameRules::PostGameReport.generate!(
        session: session,
        state: state,
        output_root: directory,
        now: generated_at
      )
      html = File.read(metadata.fetch("path"))

      assert File.exist?(metadata.fetch("path"))
      assert_match(/caesars-gallic-war-session-#{session.id}-20260807-201500\.html\z/, metadata.fetch("path"))
      assert_equal generated_at.iso8601, metadata.fetch("generatedAt")
      assert_includes html, "Caesar&#39;s Campaign Prevails"
      assert_includes html, "Eight years in Gaul"
      assert_includes html, "Turning points"
      assert_includes html, "Roman wins the battle in Helvetii."
      assert_includes html, "Legion VII"
      assert_includes html, "Full campaign chronicle"
      assert_includes html, "&lt;script&gt;alert(&#39;Gaul&#39;)&lt;/script&gt;"
      assert_not_includes html, "<script>alert('Gaul')</script>"
    end
  end

  test "refuses to write a report before all eight turns are complete" do
    state = report_state.merge("turn" => 6, "phase" => "Card Phase", "gameOver" => nil)

    error = assert_raises(ArgumentError) do
      GameRules::PostGameReport.generate!(session: GameSession.new(id: 99), state: state)
    end

    assert_equal "A post-game report requires a completed eight-turn campaign.", error.message
  end

  private

  def report_state
    {
      "turn" => 7,
      "phase" => "Game Over",
      "active" => "roman",
      "mode" => "solitaire",
      "supply" => 8,
      "vp" => 112,
      "options" => { "postGameReport" => true },
      "gameOver" => { "winner" => "roman", "result" => "Major Roman Victory", "vp" => 112 },
      "units" => {
        "legion_vii" => {
          "id" => "legion_vii", "name" => "Legion VII", "type" => "roman", "owner" => "roman",
          "location" => "sequani", "home" => "transalpine_gaul", "step" => 0
        },
        "sequani" => {
          "id" => "sequani", "name" => "Sequani", "type" => "barbarian", "owner" => "roman",
          "location" => "sequani", "home" => "sequani", "step" => 0
        }
      }
    }
  end
end
