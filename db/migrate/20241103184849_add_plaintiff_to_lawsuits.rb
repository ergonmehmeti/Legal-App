class AddPlaintiffToLawsuits < ActiveRecord::Migration[7.2]
  def change
    add_column :lawsuits, :plaintiff, :string
  end
end
