# Category scope for a legal representative ("Përfaqësues Ligjor"): besides the lawsuits they are
# assigned to, they see (read only) ALL lawsuits of these categories, e.g. both Përmbarimore ones.
# Keys of Lawsuit.categories. Empty for everyone else. Existing users get [] (no change).
class AddCategoryScopesToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :category_scopes, :string, array: true, default: [], null: false
  end
end
