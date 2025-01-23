class AddLawsuitRiskToLawsuits < ActiveRecord::Migration[7.2]
  def change
    add_column :lawsuits, :lawsuit_risk, :integer
  end
end
