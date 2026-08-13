class AddUniqueIndexToLawsuitNumber < ActiveRecord::Migration[7.2]
  def up
    # Step 1: Find and fix duplicate lawsuit_numbers among active lawsuits
    duplicates = Lawsuit.kept
                        .select(:lawsuit_number)
                        .where.not(lawsuit_number: nil)
                        .group(:lawsuit_number)
                        .having('COUNT(*) > 1')
                        .pluck(:lawsuit_number)
    
    duplicates.each do |lawsuit_number|
      # Get all lawsuits with this number, keep first, update rest
      lawsuits = Lawsuit.kept.where(lawsuit_number: lawsuit_number).order(:id)
      
      lawsuits.each_with_index do |lawsuit, index|
        next if index == 0 # Keep first one unchanged
        
        # Append suffix to make unique
        new_number = "#{lawsuit_number}_DUP#{index}"
        lawsuit.update_column(:lawsuit_number, new_number)
        puts "Updated Lawsuit ID #{lawsuit.id}: #{lawsuit_number} -> #{new_number}"
      end
    end
    
    # Step 2: Add partial unique index for active lawsuits
    add_index :lawsuits, :lawsuit_number, 
              unique: true, 
              where: "discarded_at IS NULL AND lawsuit_number IS NOT NULL",
              name: 'index_lawsuits_on_lawsuit_number_active'
  end
  
  def down
    remove_index :lawsuits, name: 'index_lawsuits_on_lawsuit_number_active'
  end
end
