class AddDeletionDetailsToLawsuits < ActiveRecord::Migration[7.2]
  def change
    add_column :lawsuits, :deletion_reason, :text
    add_column :lawsuits, :deleted_by_user_id, :integer
    add_column :lawsuits, :deleted_at, :datetime
  end
end
