class AddContextTypeToLawsuits < ActiveRecord::Migration[7.2]
  def change
    add_column :lawsuits, :context_type, :string
  end
end
