class AddDescriptionToLawsuits < ActiveRecord::Migration[7.2]
  def change
    add_column :lawsuits, :description, :text
  end
end
