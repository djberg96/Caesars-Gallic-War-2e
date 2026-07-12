class GameSessionsController < ApplicationController
  rescue_from GameRules::ActionPhase::InvalidAction, with: :invalid_action
  rescue_from GameRules::CardPhase::InvalidAction, with: :invalid_action
  rescue_from GameRules::Movement::InvalidMove, with: :invalid_move

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

  def discard_card
    session = GameSession.find(params[:id])
    result = GameRules::CardPhase.new(session: session, state: state_params).discard!(
      player: params.require(:player)
    )

    render json: { game_session_id: session.id, state: result }
  end

  def start_movement
    session = GameSession.find(params[:id])
    result = GameRules::ActionPhase.new(session: session, state: state_params).start_movement!

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
