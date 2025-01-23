class AddLawsuitAmountClaimToLawsuits < ActiveRecord::Migration[7.2]
  def change
    add_column :lawsuits, :lawsuit_amount_claim, :decimal
  end
end
