class AddDetailsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :name, :string
    add_column :users, :surname, :string
    add_column :users, :kt_id, :integer
  end
end
