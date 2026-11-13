# Courts ("Gjykatat") managed in the Admin area instead of the hard-coded list (see TODO_COURTS.md).
# lawsuits.court is NOT touched: it keeps storing the court's name as text, so no lawsuit changes.
# The table is filled with the current names (same order as the old list in Lawsuit).
class CreateCourts < ActiveRecord::Migration[7.2]
  # The list as it was in app/models/lawsuit.rb (enum court) when this migration was written.
  # Written out here (not read from the model) so the migration never changes later.
  NAMES = [
    "Gjykata Themelore",
    "Gjykata Themelore Rigjykim 2",
    "Gjykata Administrative",
    "Gjykata Komerciale Dh.Sh.1",
    "Gjykata Komerciale Dh.SH.2",
    "Gjykata Komerciale Dh.Sh.1 Rigjykim",
    "Gjykata Komerciale Dh.SH.2 Rigjykim",
    "Gjykata e Apelit",
    "Gjykata e Apelit 2",
    "Gjykata Supreme",
    "Gjykata Supreme 2",
    "Gjykata Kushtetuese"
  ].freeze

  def up
    create_table :courts do |t|
      t.string :name, null: false
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 0 # order in the dropdown
      t.timestamps
    end
    # Unique ignoring capitals ("Gjykata Themelore" = "gjykata themelore"), same as the Court model
    add_index :courts, "LOWER(name)", unique: true, name: "index_courts_on_lower_name"

    NAMES.each_with_index do |name, index|
      execute <<~SQL
        INSERT INTO courts (name, active, position, created_at, updated_at)
        VALUES (#{quote(name)}, TRUE, #{(index + 1) * 10}, NOW(), NOW())
      SQL
    end

    # Safety net: a court name that lawsuits use but that is not in the list above (should not
    # happen, see TODO_COURTS.md Step 0) is added as an inactive court, so it is visible in Admin
    # and nothing is hidden. Capitals are ignored: "gjykata themelore" counts as "Gjykata Themelore"
    # and is not added again. Lawsuits themselves are not changed.
    execute <<~SQL
      INSERT INTO courts (name, active, position, created_at, updated_at)
      SELECT DISTINCT ON (LOWER(lawsuits.court)) lawsuits.court, FALSE, 1000, NOW(), NOW()
      FROM lawsuits
      WHERE lawsuits.court IS NOT NULL AND lawsuits.court <> ''
        AND LOWER(lawsuits.court) NOT IN (SELECT LOWER(name) FROM courts)
      ORDER BY LOWER(lawsuits.court), lawsuits.court
    SQL
  end

  def down
    drop_table :courts
  end

  private

  def quote(value)
    connection.quote(value)
  end
end
