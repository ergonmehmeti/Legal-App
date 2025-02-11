class CreateProvisions < ActiveRecord::Migration[7.2]
  def change
    create_table :provisions do |t|
      t.references :lawsuit, null: false, foreign_key: true
      t.decimal :provision_value
      t.integer :provision_year

      t.timestamps
    end
  end
end
