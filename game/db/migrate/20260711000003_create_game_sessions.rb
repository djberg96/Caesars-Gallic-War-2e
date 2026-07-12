class CreateGameSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :game_sessions do |t|
      t.json :data, null: false, default: {}

      t.timestamps
    end
  end
end
