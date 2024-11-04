class AddCategoryToLawsuit < ActiveRecord::Migration[7.2]
  def change
    add_column :lawsuits, :category, :string
  end
end
