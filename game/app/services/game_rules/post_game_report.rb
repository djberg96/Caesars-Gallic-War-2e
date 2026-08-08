require "cgi"
require "fileutils"
require "pathname"

module GameRules
  class PostGameReport
    YEARS = ["58 BC", "57 BC", "56 BC", "55 BC", "54 BC", "53 BC", "52 BC", "51 BC"].freeze
    REPORT_DIRECTORY = Rails.root.join("storage", "session_reports")
    MAX_HIGHLIGHTS_PER_YEAR = 6

    class << self
      def enabled?(state)
        ActiveModel::Type::Boolean.new.cast(state.dig("options", "postGameReport"))
      end

      def record!(state, message)
        return unless enabled?(state)

        state["campaignLog"] ||= []
        state["campaignLog"] << {
          "turn" => state.fetch("turn", 0).to_i,
          "year" => YEARS.fetch(state.fetch("turn", 0).to_i, "Unknown year"),
          "phase" => state.fetch("phase", "Setup"),
          "active" => state.fetch("active", "roman"),
          "message" => message.to_s
        }
      end

      def capture_year!(state, controlled_tribes:)
        return unless enabled?(state)

        turn = state.fetch("turn", 0).to_i
        snapshots = state["campaignSnapshots"] ||= []
        previous_vp = snapshots.reject { |snapshot| snapshot.fetch("turn", -1).to_i == turn }.last&.fetch("vp", 0).to_i
        snapshot = {
          "turn" => turn,
          "year" => YEARS.fetch(turn),
          "vp" => state.fetch("vp", 0).to_i,
          "vpGained" => state.fetch("vp", 0).to_i - previous_vp,
          "supply" => state.fetch("supply", 0).to_i,
          "controlledTribes" => controlled_tribes.to_i,
          "romanAllies" => roman_allies(state),
          "fieldLegions" => field_legions(state),
          "eliminatedLegions" => eliminated_legions(state),
          "romanForces" => roman_forces(state),
          "highlights" => highlights_for_turn(state, turn)
        }
        snapshots.reject! { |existing| existing.fetch("turn", -1).to_i == turn }
        snapshots << snapshot
        snapshots.sort_by! { |existing| existing.fetch("turn").to_i }
      end

      def generate!(session:, state:, output_root: REPORT_DIRECTORY, now: Time.current)
        raise ArgumentError, "A post-game report requires a completed eight-turn campaign." unless completed_campaign?(state)

        directory = Pathname.new(output_root.to_s)
        FileUtils.mkdir_p(directory)
        filename = "caesars-gallic-war-session-#{session.id}-#{now.strftime("%Y%m%d-%H%M%S")}.html"
        path = directory.join(filename)
        File.write(path, new(session: session, state: state, generated_at: now).render)

        relative_path = begin
          path.relative_path_from(Rails.root).to_s
        rescue ArgumentError
          path.to_s
        end
        {
          "path" => path.expand_path.to_s,
          "relativePath" => relative_path,
          "generatedAt" => now.iso8601
        }
      end

      private

      def completed_campaign?(state)
        state.fetch("turn", 0).to_i == YEARS.length - 1 && state["phase"] == "Game Over" && state["gameOver"].present?
      end

      def current_strength(unit)
        strengths = Array(unit["strengths"])
        strengths = Array(UnitType.find_by(key: unit["id"])&.strengths) if strengths.empty?
        strengths.fetch(unit.fetch("step", 0).to_i, 0).to_i
      end

      def on_board?(unit)
        !unit["location"].in?([nil, "offboard", "eliminated"])
      end

      def roman_allies(state)
        state.fetch("units", {}).values.count do |unit|
          unit["owner"] == "roman" && unit["type"] == "barbarian" && on_board?(unit) && current_strength(unit).positive?
        end
      end

      def field_legions(state)
        state.fetch("units", {}).values.count do |unit|
          unit["owner"] == "roman" && unit["type"] == "roman" && on_board?(unit) && unit["location"] != "roman_off_map" && current_strength(unit).positive?
        end
      end

      def eliminated_legions(state)
        state.fetch("units", {}).values.count do |unit|
          unit["type"] == "roman" && unit["location"] == "eliminated"
        end
      end

      def roman_forces(state)
        state.fetch("units", {}).values.filter_map do |unit|
          next unless unit["owner"] == "roman" && on_board?(unit) && current_strength(unit).positive?

          {
            "name" => unit.fetch("name"),
            "type" => unit.fetch("type"),
            "location" => unit.fetch("location"),
            "strength" => current_strength(unit)
          }
        end.sort_by { |unit| [unit.fetch("location"), unit.fetch("name")] }
      end

      def highlights_for_turn(state, turn)
        entries = Array(state["campaignLog"]).select { |entry| entry.fetch("turn", -1).to_i == turn }
        interesting = entries.select { |entry| interesting?(entry.fetch("message")) }
        (interesting.presence || entries.last(MAX_HIGHLIGHTS_PER_YEAR)).last(MAX_HIGHLIGHTS_PER_YEAR).map { |entry| entry.fetch("message") }
      end

      def interesting?(message)
        message.match?(/wins the battle|holds .* after battle|eliminated|Revolt|political action succeeds|Yearly objective|Roman Reinforcements|Supply and Attrition|Campaign complete/i)
      end
    end

    def initialize(session:, state:, generated_at:)
      @session = session
      @state = state
      @generated_at = generated_at
    end

    def render
      <<~HTML
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>#{h(report_title)}</title>
          <style>#{stylesheet}</style>
        </head>
        <body>
          <main>
            <header class="hero">
              <p class="eyebrow">Caesar's Gallic War · Session #{@session.id}</p>
              <h1>#{h(report_title)}</h1>
              <p class="lede">#{h(opening_summary)}</p>
              <div class="result-grid">
                #{stat("Result", game_over.fetch("result"))}
                #{stat("Roman VP", game_over.fetch("vp"))}
                #{stat("Mode", mode_name)}
                #{stat("Final Supply", @state.fetch("supply", 0))}
              </div>
            </header>

            <section>
              <div class="section-heading">
                <p class="eyebrow">The campaign at a glance</p>
                <h2>Eight years in Gaul</h2>
              </div>
              #{vp_chart}
              <div class="year-grid">#{snapshots.map { |snapshot| year_card(snapshot) }.join}</div>
            </section>

            <section>
              <div class="section-heading">
                <p class="eyebrow">Dispatches</p>
                <h2>Turning points</h2>
              </div>
              <div class="turning-points">#{turning_points}</div>
            </section>

            <section>
              <div class="section-heading">
                <p class="eyebrow">Final positions</p>
                <h2>Where the campaign ended</h2>
              </div>
              #{final_disposition}
            </section>

            <details>
              <summary>Full campaign chronicle</summary>
              #{full_chronicle}
            </details>

            <footer>
              Generated #{h(@generated_at.strftime("%B %-d, %Y at %-I:%M %p"))} by Caesar's Gallic War.
            </footer>
          </main>
        </body>
        </html>
      HTML
    end

    private

    def game_over
      @state.fetch("gameOver")
    end

    def snapshots
      Array(@state["campaignSnapshots"]).sort_by { |snapshot| snapshot.fetch("turn", 0).to_i }
    end

    def campaign_log
      Array(@state["campaignLog"])
    end

    def report_title
      game_over.fetch("winner") == "roman" ? "Caesar's Campaign Prevails" : "Gaul Defies Rome"
    end

    def opening_summary
      vp = game_over.fetch("vp").to_i
      result = game_over.fetch("result")
      peak = snapshots.max_by { |snapshot| snapshot.fetch("vpGained", 0).to_i }
      surge = peak ? " The sharpest Roman advance came in #{peak.fetch("year")}, when Caesar gained #{peak.fetch("vpGained")} VP." : ""
      "The eight-year campaign ended in a #{result.downcase} with #{vp} Roman victory points.#{surge}"
    end

    def mode_name
      { "solitaire" => "Solitaire Roman", "hotseat" => "Hotseat", "ai" => "AI Opponent" }.fetch(@state.fetch("mode", "hotseat"), @state.fetch("mode", "hotseat").titleize)
    end

    def stat(label, value)
      %(<div class="stat"><span>#{h(label)}</span><strong>#{h(value)}</strong></div>)
    end

    def vp_chart
      return %(<p class="empty">No yearly snapshots were recorded.</p>) if snapshots.empty?

      width = 760
      height = 230
      padding = 34
      max_vp = [snapshots.map { |snapshot| snapshot.fetch("vp", 0).to_i }.max.to_i, 10].max
      step_x = snapshots.one? ? 0 : (width - padding * 2).fdiv(snapshots.length - 1)
      points = snapshots.each_with_index.map do |snapshot, index|
        x = padding + index * step_x
        y = height - padding - (snapshot.fetch("vp", 0).to_i.fdiv(max_vp) * (height - padding * 2))
        [x.round(1), y.round(1), snapshot]
      end
      line = points.map { |x, y, _snapshot| "#{x},#{y}" }.join(" ")
      dots = points.map do |x, y, snapshot|
        %(<g><circle cx="#{x}" cy="#{y}" r="6"></circle><text x="#{x}" y="#{y - 13}" text-anchor="middle">#{snapshot.fetch("vp")}</text><text class="year" x="#{x}" y="#{height - 8}" text-anchor="middle">#{h(snapshot.fetch("year"))}</text></g>)
      end.join
      <<~SVG
        <div class="chart" role="img" aria-label="Roman victory points by year">
          <svg viewBox="0 0 #{width} #{height}" preserveAspectRatio="xMidYMid meet">
            <line class="axis" x1="#{padding}" y1="#{height - padding}" x2="#{width - padding}" y2="#{height - padding}"></line>
            <polyline points="#{line}"></polyline>
            #{dots}
          </svg>
        </div>
      SVG
    end

    def year_card(snapshot)
      highlights = Array(snapshot["highlights"])
      highlight_html = if highlights.empty?
        %(<p class="empty">No major event was recorded.</p>)
      else
        %(<ul>#{highlights.map { |message| "<li>#{h(message)}</li>" }.join}</ul>)
      end
      <<~HTML
        <article class="year-card">
          <header><span>Turn #{snapshot.fetch("turn").to_i + 1}</span><h3>#{h(snapshot.fetch("year"))}</h3></header>
          <p class="year-summary">#{h(year_summary(snapshot))}</p>
          <div class="mini-stats">
            <span><b>#{snapshot.fetch("vp")}</b> VP</span>
            <span><b>#{snapshot.fetch("supply")}</b> supply</span>
            <span><b>#{snapshot.fetch("romanAllies")}</b> allies</span>
          </div>
          #{highlight_html}
        </article>
      HTML
    end

    def year_summary(snapshot)
      gain = snapshot.fetch("vpGained", 0).to_i
      momentum = if gain >= 10
        "Rome made a dramatic advance"
      elsif gain.positive?
        "Rome added #{gain} VP"
      elsif gain.zero?
        "The Roman position held without a VP gain"
      else
        "Roman fortunes declined by #{gain.abs} VP"
      end
      losses = snapshot.fetch("eliminatedLegions", 0).to_i
      loss_text = losses.positive? ? ", with #{losses} legion#{losses == 1 ? "" : "s"} eliminated" : ""
      legion_count = snapshot.fetch("fieldLegions").to_i
      "#{momentum}, ending with #{snapshot.fetch("controlledTribes")} controlled tribal areas and #{legion_count} legion#{legion_count == 1 ? "" : "s"} in the field#{loss_text}."
    end

    def turning_points
      entries = campaign_log.select { |entry| self.class.send(:interesting?, entry.fetch("message")) }
      entries = entries.group_by { |entry| entry.fetch("turn", 0).to_i }
        .sort
        .flat_map { |_turn, year_entries| year_entries.last(2) }
        .first(12)
      return %(<p class="empty">No turning points were recorded.</p>) if entries.empty?

      entries.map do |entry|
        <<~HTML
          <article class="dispatch">
            <span>#{h(entry.fetch("year", ""))}</span>
            <p>#{h(entry.fetch("message"))}</p>
          </article>
        HTML
      end.join
    end

    def final_disposition
      forces = snapshots.last&.fetch("romanForces", []) || []
      return %(<p class="empty">No Roman-controlled forces remained on the board.</p>) if forces.empty?

      groups = forces.group_by { |force| force.fetch("location") }
      %(<div class="disposition-grid">#{groups.sort.map { |location, units| disposition_card(location, units) }.join}</div>)
    end

    def disposition_card(location, units)
      area = Area.find_by(key: location)&.name || location.to_s.titleize
      counters = units.map do |unit|
        %(<li><span>#{h(unit.fetch("name"))}</span><b>#{unit.fetch("strength")}</b></li>)
      end.join
      %(<article class="disposition"><h3>#{h(area)}</h3><ul>#{counters}</ul></article>)
    end

    def full_chronicle
      return %(<p class="empty">No chronicle entries were recorded.</p>) if campaign_log.empty?

      campaign_log.group_by { |entry| entry.fetch("year", "Campaign") }.map do |year, entries|
        %(<section class="chronicle-year"><h3>#{h(year)}</h3><ol>#{entries.map { |entry| "<li>#{h(entry.fetch("message"))}</li>" }.join}</ol></section>)
      end.join
    end

    def h(value)
      CGI.escapeHTML(value.to_s)
    end

    def stylesheet
      <<~CSS
        :root { color-scheme: dark; --ink: #f5ecd8; --muted: #c8bea6; --gold: #ddb759; --red: #ad4f3f; --green: #426b4a; --panel: #20251f; --line: #635a38; }
        * { box-sizing: border-box; }
        body { margin: 0; background: #111510; color: var(--ink); font: 17px/1.55 Georgia, "Times New Roman", serif; }
        main { width: min(1120px, calc(100% - 32px)); margin: 0 auto; padding: 48px 0 64px; }
        h1, h2, h3, p { margin-top: 0; }
        h1 { max-width: 760px; margin-bottom: 16px; color: var(--gold); font-size: clamp(2.8rem, 7vw, 5.5rem); line-height: .92; }
        h2 { margin-bottom: 24px; font-size: 2.25rem; }
        h3 { margin-bottom: 8px; }
        section { margin-top: 58px; }
        .hero { padding: 44px; border: 1px solid var(--line); border-radius: 20px; background: linear-gradient(135deg, #282d24, #191d18); box-shadow: 0 22px 60px #0008; }
        .eyebrow, .stat span, .year-card header span, .dispatch > span { color: var(--gold); font: 700 .77rem/1.2 system-ui, sans-serif; letter-spacing: .16em; text-transform: uppercase; }
        .lede { max-width: 800px; color: var(--muted); font-size: 1.22rem; }
        .result-grid { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 12px; margin-top: 32px; }
        .stat { padding: 16px; border: 1px solid var(--line); border-radius: 10px; background: #171b16; }
        .stat span, .stat strong { display: block; }
        .stat strong { margin-top: 5px; font-size: 1.25rem; }
        .chart { padding: 18px; border: 1px solid var(--line); border-radius: 16px; background: #1a1f19; }
        .chart svg { display: block; width: 100%; max-height: 260px; }
        .chart .axis { stroke: #625f52; stroke-width: 2; }
        .chart polyline { fill: none; stroke: var(--gold); stroke-width: 5; stroke-linecap: round; stroke-linejoin: round; }
        .chart circle { fill: var(--red); stroke: #f5d98c; stroke-width: 3; }
        .chart text { fill: var(--ink); font: 700 16px system-ui, sans-serif; }
        .chart text.year { fill: var(--muted); font-size: 13px; }
        .year-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px; margin-top: 18px; }
        .year-card { padding: 24px; border: 1px solid var(--line); border-radius: 14px; background: var(--panel); }
        .year-card header { display: flex; align-items: baseline; justify-content: space-between; gap: 16px; }
        .year-card h3 { color: var(--gold); font-size: 1.55rem; }
        .year-summary { color: var(--muted); }
        .mini-stats { display: flex; flex-wrap: wrap; gap: 8px; margin: 14px 0; }
        .mini-stats span { padding: 6px 10px; border-radius: 999px; background: #151914; color: var(--muted); font: .82rem system-ui, sans-serif; }
        .year-card ul { margin: 14px 0 0; padding-left: 20px; }
        .year-card li { margin: 6px 0; }
        .turning-points { display: grid; gap: 12px; }
        .dispatch { display: grid; grid-template-columns: 90px 1fr; gap: 18px; padding: 18px 22px; border-left: 5px solid var(--red); background: var(--panel); }
        .dispatch p { margin: 0; }
        .disposition-grid { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 14px; }
        .disposition { padding: 20px; border: 1px solid var(--line); border-radius: 12px; background: var(--panel); }
        .disposition h3 { color: var(--gold); }
        .disposition ul { margin: 0; padding: 0; list-style: none; }
        .disposition li { display: flex; justify-content: space-between; gap: 18px; padding: 7px 0; border-top: 1px solid #ffffff12; }
        .disposition li b { display: grid; width: 28px; height: 28px; place-items: center; border-radius: 50%; background: #0e110d; color: var(--gold); }
        details { margin-top: 58px; padding: 22px; border: 1px solid var(--line); border-radius: 12px; background: #181c17; }
        summary { cursor: pointer; color: var(--gold); font-size: 1.25rem; font-weight: 700; }
        .chronicle-year { margin-top: 28px; }
        .chronicle-year ol { color: var(--muted); }
        footer { margin-top: 48px; color: #8f897b; font: .8rem system-ui, sans-serif; text-align: center; }
        .empty { color: var(--muted); font-style: italic; }
        @media (max-width: 760px) { .hero { padding: 28px; } .result-grid, .year-grid, .disposition-grid { grid-template-columns: 1fr; } .dispatch { grid-template-columns: 1fr; gap: 6px; } }
        @media print { body { background: white; color: #171717; } main { width: 100%; padding: 0; } .hero, .year-card, .chart, .dispatch, .disposition, details { background: white; color: #171717; box-shadow: none; break-inside: avoid; } }
      CSS
    end
  end
end
