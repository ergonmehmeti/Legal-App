class AddLawsuitStateToLawsuits < ActiveRecord::Migration[7.2]
  def change
    add_column :lawsuits, :lawsuit_state, :string
  end
end
