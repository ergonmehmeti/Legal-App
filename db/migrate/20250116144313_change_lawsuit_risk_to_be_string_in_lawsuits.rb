class ChangeLawsuitRiskToBeStringInLawsuits < ActiveRecord::Migration[7.2]
  def change
    change_column :lawsuits, :lawsuit_risk, :string
  end
end
