Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "board#index"

  resources :game_sessions, only: :create do
    post :commit_card, on: :member
    post :deal, on: :member
    post :discard_card, on: :member
    post :draw_bot_card, on: :member
    post :end_turn, on: :member
    post :move, on: :member
    post :reveal_cards, on: :member
    post :resolve_battles, on: :member
    post :start_movement, on: :member
    post :activate_movement_area, on: :member
    post :undo_move, on: :member
    post :supply_action, on: :member
    post :activate_neutral, on: :member
    post :political_action, on: :member
    post :event_action, on: :member
  end
end
