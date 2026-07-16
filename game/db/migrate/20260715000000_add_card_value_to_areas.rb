class AddCardValueToAreas < ActiveRecord::Migration[8.1]
  def change
    add_column :areas, :card_value, :integer
  end
end
