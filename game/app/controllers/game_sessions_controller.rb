class GameSessionsController < ApplicationController
  rescue_from GameRules::ActionPhase::InvalidAction, with: :invalid_action
  rescue_from GameRules::CardPhase::InvalidAction, with: :invalid_action
  rescue_from GameRules::EndTurn::InvalidAction, with: :invalid_action
  rescue_from GameRules::Movement::InvalidMove, with: :invalid_move
  rescue_from GameRules::UndoMove::InvalidUndo, with: :invalid_action
  rescue_from GameRules::Battle::InvalidAction, with: :invalid_action

  def create
    session = GameSession.create!(data: create_state)
    session.sync_from_data!
    render json: { game_session_id: session.id, state: session.data }
  end

  def move
    session = GameSession.find(params[:id])
    result = GameRules::Movement.new(session: session, state: action_state(session), rolls: params[:rolls]).move!(
      unit_id: params.require(:unit_id),
      target: params.require(:target)
    )

    render json: { game_session_id: session.id, state: result }
  end

  def deal
    session = GameSession.find(params[:id])
    result = GameRules::Deal.new(session: session, state: action_state(session)).deal!

    render json: { game_session_id: session.id, state: result }
  end

  def draw_bot_card
    session = GameSession.find(params[:id])
    result = GameRules::Bot.new(
      session: session,
      state: action_state(session),
      roll: params[:roll],
      rolls: params[:rolls],
      target: params[:target]
    ).draw!

    render json: { game_session_id: session.id, state: result }
  end

  def commit_card
    session = GameSession.find(params[:id])
    result = GameRules::CardPhase.new(session: session, state: action_state(session)).commit!(
      player: params.require(:player),
      card_id: params.require(:card_id)
    )

    render json: { game_session_id: session.id, state: result }
  end

  def reveal_cards
    session = GameSession.find(params[:id])
    result = GameRules::CardPhase.new(session: session, state: action_state(session)).reveal!

    render json: { game_session_id: session.id, state: result }
  end

  def resolve_battles
    session = GameSession.find(params[:id])
    result = GameRules::Battle.new(session: session, state: action_state(session), rolls: params[:rolls]).resolve!(
      area_id: params[:area_id],
      main_origin: params[:main_origin]
    )

    render json: { game_session_id: session.id, state: result }
  end

  def battle_action
    session = GameSession.find(params[:id])
    result = GameRules::Battle.new(session: session, state: action_state(session), rolls: params[:rolls]).act!(
      action: params.require(:battle_action),
      unit_id: params[:unit_id],
      target: params[:target]
    )

    render json: { game_session_id: session.id, state: result }
  end

  def undo_move
    session = GameSession.find(params[:id])
    result = GameRules::UndoMove.new(session: session, state: action_state(session)).undo!

    render json: { game_session_id: session.id, state: result }
  end

  def discard_card
    session = GameSession.find(params[:id])
    result = GameRules::CardPhase.new(session: session, state: action_state(session)).discard!(
      player: params.require(:player)
    )

    render json: { game_session_id: session.id, state: result }
  end

  def end_turn
    session = GameSession.find(params[:id])
    result = GameRules::EndTurn.new(
      session: session,
      state: action_state(session),
      harvest_roll: params[:harvest_roll],
      wintering_unit_ids: params[:wintering_unit_ids],
      replacement_steps: params[:replacement_steps],
      supply_production_acknowledged: params[:supply_production_acknowledged],
      reinforcement_builds: params[:reinforcement_builds]
    ).end_turn!

    render json: { game_session_id: session.id, state: result }
  end

  def start_movement
    session = GameSession.find(params[:id])
    result = GameRules::ActionPhase.new(session: session, state: action_state(session)).start_movement!

    render json: { game_session_id: session.id, state: result }
  end

  def supply_action
    session = GameSession.find(params[:id])
    result = GameRules::ActionPhase.new(session: session, state: action_state(session)).supply!

    render json: { game_session_id: session.id, state: result }
  end

  def activate_neutral
    session = GameSession.find(params[:id])
    result = GameRules::ActionPhase.new(session: session, state: action_state(session)).activate_neutral!

    render json: { game_session_id: session.id, state: result }
  end

  def political_action
    session = GameSession.find(params[:id])
    result = GameRules::ActionPhase.new(session: session, state: action_state(session)).political!(
      area_id: params.require(:area_id),
      roll: params[:roll]
    )

    render json: { game_session_id: session.id, state: result }
  end

  def event_action
    session = GameSession.find(params[:id])
    result = GameRules::ActionPhase.new(session: session, state: action_state(session)).event!(
      area_id: params[:area_id],
      unit_id: params[:unit_id]
    )

    render json: { game_session_id: session.id, state: result }
  end

  def activate_movement_area
    session = GameSession.find(params[:id])
    result = GameRules::ActionPhase.new(session: session, state: action_state(session)).activate_movement_area!(
      area_id: params.require(:area_id)
    )

    render json: { game_session_id: session.id, state: result }
  end

  def update_options
    session = GameSession.find(params[:id])
    if game_started?(session.data)
      render json: { error: "Optional rules cannot be changed after a card has been played." }, status: :unprocessable_entity
      return
    end

    state = session.data.deep_dup
    state["options"] ||= {}
    state["options"]["yearlyObjectives"] = ActiveModel::Type::Boolean.new.cast(params[:yearly_objectives])
    session.update!(data: state)

    render json: { game_session_id: session.id, options: state.fetch("options") }
  end

  def acknowledge_turn
    session = GameSession.find(params[:id])
    state = session.data.deep_dup
    state["turnAnnouncementPending"] = false
    session.update!(data: state)

    render json: { game_session_id: session.id, state: state }
  end

  private

  def create_state
    return state_params if params[:state].present?

    GameRules::Setup.new(view_context: helpers).state(
      mode: params[:mode],
      yearly_objectives: params[:yearly_objectives]
    )
  end

  def state_params
    params.require(:state).permit!.to_h
  end

  def action_state(session)
    submitted = state_params
    preserve_server_battle_metadata!(submitted, session.data)
    normalize_special_unit_state!(submitted)
    return submitted unless game_started?(session.data)

    submitted["options"] ||= {}
    submitted["options"]["yearlyObjectives"] = session.data.dig("options", "yearlyObjectives") || false
    submitted
  end

  def preserve_server_battle_metadata!(submitted, persisted)
    submitted["pendingBattleEntries"] = persisted.fetch("pendingBattleEntries", {}).deep_dup

    submitted.fetch("units", {}).each do |unit_id, unit|
      persisted_entry = persisted.dig("units", unit_id, "battleEntry")
      if persisted_entry.present?
        unit["battleEntry"] = persisted_entry.deep_dup
      else
        unit.delete("battleEntry")
      end
    end
  end

  def normalize_special_unit_state!(state)
    helvetii = state.dig("units", "helvetii")
    nantuates = state.dig("units", "nantuates")
    return unless helvetii&.fetch("location", nil) == "offboard" && nantuates

    nantuates["home"] = "helvetii"
    return unless nantuates["location"] == "offboard"

    nantuates["location"] = "helvetii"
    nantuates["step"] = 0
  end

  def game_started?(state)
    state.fetch("turn", 0).to_i.positive? ||
      Array(state["discard"]).any? ||
      state["currentAction"].present? ||
      state["movement"].present? ||
      state["battle"].present? ||
      ActiveModel::Type::Boolean.new.cast(state["revealed"]) ||
      (state["committed"] || {}).values.compact.any? ||
      ActiveModel::Type::Boolean.new.cast(state["diceRolledThisTurn"])
  end

  def invalid_move(error)
    render json: { error: error.message }, status: :unprocessable_entity
  end

  def invalid_action(error)
    render json: { error: error.message }, status: :unprocessable_entity
  end
end
