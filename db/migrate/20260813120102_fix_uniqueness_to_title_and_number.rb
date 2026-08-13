class FixUniquenessToTitleAndNumber < ActiveRecord::Migration[7.2]
  def up
    # Remove the old single-column unique index
    remove_index :lawsuits, name: 'index_lawsuits_on_lawsuit_number_active' if index_exists?(:lawsuits, :lawsuit_number, name: 'index_lawsuits_on_lawsuit_number_active')
    
    # Add composite unique index on title + lawsuit_number for active lawsuits
    # This allows same lawsuit_number OR same title, but not same combination
    add_index :lawsuits, [:title, :lawsuit_number], 
              unique: true, 
              where: "discarded_at IS NULL",
              name: 'index_lawsuits_on_title_and_number_active'
  end
  
  def down
    remove_index :lawsuits, name: 'index_lawsuits_on_title_and_number_active'
    
    # Restore the old index
    add_index :lawsuits, :lawsuit_number, 
              unique: true, 
              where: "discarded_at IS NULL AND lawsuit_number IS NOT NULL",
              name: 'index_lawsuits_on_lawsuit_number_active'
  end
end
