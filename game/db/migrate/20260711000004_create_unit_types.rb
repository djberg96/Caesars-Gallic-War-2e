class CreateUnitTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :unit_types do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.string :category, null: false
      t.string :home, null: false
      t.string :initiative, null: false
      t.integer :fire, null: false
      t.json :strengths, null: false, default: []
      t.string :image_path, null: false

      t.timestamps
    end

    add_index :unit_types, :key, unique: true
  end
end
