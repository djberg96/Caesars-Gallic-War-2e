class AddStateColumnsToGameSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :game_sessions, :turn_index, :integer, null: false, default: 0
    add_column :game_sessions, :phase, :string, null: false, default: "Card Phase"
    add_column :game_sessions, :active_player, :string, null: false, default: "roman"
    add_column :game_sessions, :supply, :integer, null: false, default: 15
    add_column :game_sessions, :vp, :integer, null: false, default: 0
    add_column :game_sessions, :mode, :string, null: false, default: "hotseat"
    add_column :game_sessions, :revealed, :boolean, null: false, default: false
    add_column :game_sessions, :dice_rolled_this_turn, :boolean, null: false, default: false
    add_column :game_sessions, :bot_neutral_activations, :integer, null: false, default: 0

    add_index :game_sessions, :mode
    add_index :game_sessions, :active_player
  end
end
