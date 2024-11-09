class AddLawsuitNumberToLawsuits < ActiveRecord::Migration[7.2]
  def change
    add_column :lawsuits, :lawsuit_number, :string
  end
end
