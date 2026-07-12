class CreateGameSessionCards < ActiveRecord::Migration[8.1]
  def change
    create_table :game_session_cards do |t|
      t.references :game_session, null: false, foreign_key: true
      t.references :card, null: false, foreign_key: true
      t.string :location, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :game_session_cards, [:game_session_id, :card_id], unique: true
    add_index :game_session_cards, [:game_session_id, :location, :position]
  end
end
