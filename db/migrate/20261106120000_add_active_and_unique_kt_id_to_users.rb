class AddActiveAndUniqueKtIdToUsers < ActiveRecord::Migration[7.2]
  def change
    # Deactivation instead of deleting users (comments / audit history stay linked)
    add_column :users, :active, :boolean, default: true, null: false

    # kt_id = Kosovo Telecom employee ID, one account per employee
    add_index :users, :kt_id, unique: true
  end
end
