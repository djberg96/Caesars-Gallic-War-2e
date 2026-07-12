class CreateGameUnits < ActiveRecord::Migration[8.1]
  def change
    create_table :game_units do |t|
      t.references :game_session, null: false, foreign_key: true
      t.references :unit_type, null: false, foreign_key: true
      t.references :area, foreign_key: true
      t.string :location, null: false
      t.string :owner, null: false
      t.integer :step, null: false, default: 0

      t.timestamps
    end

    add_index :game_units, [:game_session_id, :unit_type_id], unique: true
    add_index :game_units, :location
  end
end
