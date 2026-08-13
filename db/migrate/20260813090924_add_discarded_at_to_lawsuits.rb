class AddDiscardedAtToLawsuits < ActiveRecord::Migration[7.2]
  def change
    add_column :lawsuits, :discarded_at, :datetime
    add_index :lawsuits, :discarded_at
  end
end
