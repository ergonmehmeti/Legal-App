class RemoveStatusFromLawsuits < ActiveRecord::Migration[7.2]
  def change
    remove_column :lawsuits, :status, :string
  end
end
