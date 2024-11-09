class AddLawsuitClaimToLawsuits < ActiveRecord::Migration[7.2]
  def change
    add_column :lawsuits, :lawsuit_claim, :string
  end
end
