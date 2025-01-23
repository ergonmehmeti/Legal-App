class AddProvisionToLawsuits < ActiveRecord::Migration[7.2]
  def change
    add_column :lawsuits, :provision, :decimal
  end
end
