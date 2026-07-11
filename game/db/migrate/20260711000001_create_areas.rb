class CreateAreas < ActiveRecord::Migration[8.1]
  def change
    create_table :areas do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.integer :x, null: false
      t.integer :y, null: false
      t.string :region
      t.boolean :sea, null: false, default: false
      t.boolean :port, null: false, default: false
      t.string :fort_name
      t.integer :fort_level
      t.text :special
      t.json :tribes, null: false, default: []
      t.string :alternate_tribe

      t.timestamps
    end

    add_index :areas, :key, unique: true
  end
end
