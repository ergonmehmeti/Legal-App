class CreateLawsuits < ActiveRecord::Migration[7.2]
  def change
    create_table :lawsuits do |t|
      t.string :title

      t.timestamps
    end
  end
end
