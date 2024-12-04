class AddCourtToLawsuits < ActiveRecord::Migration[7.2]
  def change
    add_column :lawsuits, :court, :string
  end
end
