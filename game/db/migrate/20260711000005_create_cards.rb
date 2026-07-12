class CreateCards < ActiveRecord::Migration[8.1]
  def change
    create_table :cards do |t|
      t.string :key, null: false
      t.string :title, null: false
      t.string :kind, null: false
      t.integer :ap, null: false
      t.references :area, foreign_key: true

      t.timestamps
    end

    add_index :cards, :key, unique: true
  end
end
