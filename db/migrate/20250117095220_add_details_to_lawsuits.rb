class AddDetailsToLawsuits < ActiveRecord::Migration[7.2]
  def change
    add_column :lawsuits, :civil_lawsuit, :string
    add_column :lawsuits, :lawsuit_phase_procedure, :string
    add_column :lawsuits, :institution, :string
    add_column :lawsuits, :lawsuit_development_procedure, :string
  end
end
