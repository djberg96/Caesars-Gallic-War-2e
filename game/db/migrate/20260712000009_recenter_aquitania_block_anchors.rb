class RecenterAquitaniaBlockAnchors < ActiveRecord::Migration[8.1]
  def up
    update_anchor("aedui", 64, 51)
    update_anchor("allobroges", 73, 62)
    update_anchor("andes", 32, 38)
    update_anchor("arverni", 55, 62)
    update_anchor("atuatuci", 64, 29)
    update_anchor("bellovaci", 49, 27)
    update_anchor("boii", 64, 63)
    update_anchor("cadurci", 44, 73)
    update_anchor("mediomatrici", 86, 28)
    update_anchor("menapi", 71, 13)
    update_anchor("sequani", 78, 47)
    update_anchor("tarbelli", 31, 79)
    update_anchor("tolosates", 41, 85)
  end

  def down
    update_anchor("aedui", 62, 51)
    update_anchor("allobroges", 72, 62)
    update_anchor("andes", 30, 38)
    update_anchor("arverni", 53, 62)
    update_anchor("atuatuci", 62, 29)
    update_anchor("bellovaci", 47, 25)
    update_anchor("boii", 63, 63)
    update_anchor("cadurci", 42, 73)
    update_anchor("mediomatrici", 84, 28)
    update_anchor("menapi", 69, 13)
    update_anchor("sequani", 78, 45)
    update_anchor("tarbelli", 29, 82)
    update_anchor("tolosates", 39, 87)
  end

  private

  def update_anchor(key, x, y)
    execute(<<~SQL.squish)
      UPDATE areas
      SET x = #{x}, y = #{y}, updated_at = CURRENT_TIMESTAMP
      WHERE key = '#{key}'
    SQL
  end
end
