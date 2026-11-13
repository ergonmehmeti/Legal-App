# Which legal representatives (users with role legal_representative) are assigned to a lawsuit.
# A lawsuit can have several: one primary ("Përfaqësuesi kryesor") and optional secondary ones.
# All of them have the same (view-only) access; is_primary is only shown in the UI.
# New empty table: no existing data changes.
class CreateLawsuitRepresentatives < ActiveRecord::Migration[7.2]
  def change
    create_table :lawsuit_representatives do |t|
      t.references :lawsuit, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.boolean :is_primary, null: false, default: false
      t.timestamps
    end

    # The same user only once per lawsuit
    add_index :lawsuit_representatives, [:lawsuit_id, :user_id], unique: true
    # At most one primary per lawsuit
    add_index :lawsuit_representatives, :lawsuit_id, unique: true, where: "is_primary",
              name: "index_lawsuit_representatives_one_primary"
  end
end
