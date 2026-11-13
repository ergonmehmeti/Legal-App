# "Statusi Final i Lëndës": how a lawsuit ended (all categories, optional).
# Stores a key (see Lawsuit::FINAL_STATUSES). Existing lawsuits stay empty: no data changes.
class AddFinalStatusToLawsuits < ActiveRecord::Migration[7.2]
  def change
    add_column :lawsuits, :final_status, :string
  end
end
