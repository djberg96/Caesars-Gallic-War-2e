class GameSessionsController < ApplicationController
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
end
