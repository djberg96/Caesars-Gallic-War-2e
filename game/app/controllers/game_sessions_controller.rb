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
    result = GameRules::Movement.new(session: session, state: state_params).move!(
      unit_id: params.require(:unit_id),
      target: params.require(:target)
    )

    render json: { game_session_id: session.id, state: result }
  end

  def deal
    session = GameSession.find(params[:id])
    result = GameRules::Deal.new(session: session, state: state_params).deal!

    render json: { game_session_id: session.id, state: result }
  end

  def draw_bot_card
    session = GameSession.find(params[:id])
    result = GameRules::Bot.new(
      session: session,
      state: state_params,
      roll: params[:roll],
      target: params[:target]
    ).draw!

    render json: { game_session_id: session.id, state: result }
  end

  def commit_card
    session = GameSession.find(params[:id])
    result = GameRules::CardPhase.new(session: session, state: state_params).commit!(
      player: params.require(:player),
      card_id: params.require(:card_id)
    )

    render json: { game_session_id: session.id, state: result }
  end

  def reveal_cards
    session = GameSession.find(params[:id])
    result = GameRules::CardPhase.new(session: session, state: state_params).reveal!

    render json: { game_session_id: session.id, state: result }
  end

  def resolve_battles
    session = GameSession.find(params[:id])
    result = GameRules::Battle.new(session: session, state: state_params, rolls: params[:rolls]).resolve!(
      area_id: params[:area_id],
      main_origin: params[:main_origin]
    )

    render json: { game_session_id: session.id, state: result }
  end

  def battle_action
    session = GameSession.find(params[:id])
    result = GameRules::Battle.new(session: session, state: state_params, rolls: params[:rolls]).act!(
      action: params.require(:battle_action),
      unit_id: params[:unit_id],
      target: params[:target]
    )

    render json: { game_session_id: session.id, state: result }
  end

  def undo_move
    session = GameSession.find(params[:id])
    result = GameRules::UndoMove.new(session: session, state: state_params).undo!

    render json: { game_session_id: session.id, state: result }
  end

  def discard_card
    session = GameSession.find(params[:id])
    result = GameRules::CardPhase.new(session: session, state: state_params).discard!(
      player: params.require(:player)
    )

    render json: { game_session_id: session.id, state: result }
  end

  def end_turn
    session = GameSession.find(params[:id])
    result = GameRules::EndTurn.new(
      session: session,
      state: state_params,
      harvest_roll: params[:harvest_roll]
    ).end_turn!

    render json: { game_session_id: session.id, state: result }
  end

  def start_movement
    session = GameSession.find(params[:id])
    result = GameRules::ActionPhase.new(session: session, state: state_params).start_movement!

    render json: { game_session_id: session.id, state: result }
  end

  def supply_action
    session = GameSession.find(params[:id])
    result = GameRules::ActionPhase.new(session: session, state: state_params).supply!

    render json: { game_session_id: session.id, state: result }
  end

  def activate_neutral
    session = GameSession.find(params[:id])
    result = GameRules::ActionPhase.new(session: session, state: state_params).activate_neutral!

    render json: { game_session_id: session.id, state: result }
  end

  def political_action
    session = GameSession.find(params[:id])
    result = GameRules::ActionPhase.new(session: session, state: state_params).political!(
      area_id: params.require(:area_id),
      roll: params[:roll]
    )

    render json: { game_session_id: session.id, state: result }
  end

  def event_action
    session = GameSession.find(params[:id])
    result = GameRules::ActionPhase.new(session: session, state: state_params).event!(
      area_id: params[:area_id]
    )

    render json: { game_session_id: session.id, state: result }
  end

  def activate_movement_area
    session = GameSession.find(params[:id])
    result = GameRules::ActionPhase.new(session: session, state: state_params).activate_movement_area!(
      area_id: params.require(:area_id)
    )

    render json: { game_session_id: session.id, state: result }
  end

  private

  def create_state
    return state_params if params[:state].present?

    GameRules::Setup.new(view_context: helpers).state(mode: params[:mode])
  end

  def state_params
    params.require(:state).permit!.to_h
  end

  def invalid_move(error)
    render json: { error: error.message }, status: :unprocessable_entity
  end

  def invalid_action(error)
    render json: { error: error.message }, status: :unprocessable_entity
  end
end
