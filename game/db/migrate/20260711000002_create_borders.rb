class CreateBorders < ActiveRecord::Migration[8.1]
  def change
    create_table :borders do |t|
      t.references :from_area, null: false, foreign_key: { to_table: :areas }
      t.references :to_area, null: false, foreign_key: { to_table: :areas }
      t.string :kind, null: false

      t.timestamps
    end

    add_index :borders, [:from_area_id, :to_area_id], unique: true
  end
end
