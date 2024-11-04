class AddStatusToLawsuits < ActiveRecord::Migration[7.2]
  def change
    add_column :lawsuits, :status, :string
  end
end
