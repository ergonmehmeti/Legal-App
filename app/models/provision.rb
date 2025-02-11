class Provision < ApplicationRecord
  belongs_to :lawsuit
  validates :provision_value, presence: true, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :provision_year, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 2000 }, allow_nil: true

  # Helper method to access human-readable category
  def lawsuit_category
    lawsuit&.enum_value(:category)  # Fetches the human-readable category from Lawsuit
  end

  # Group provisions by category and year with sum of values
  def self.grouped_by_category_and_year
    provisions = includes(:lawsuit).where.not(provision_year: nil)
    grouped_data = provisions.group_by { |provision| provision.lawsuit_category }  # Now using lawsuit_category for human-readable category

    grouped_data.each do |category, provisions|
      provisions_by_year = provisions.group_by { |provision| provision.provision_year }

      # Compute yearly sums
      provisions_by_year.each do |year, provisions_in_year|
        sum_of_values = provisions_in_year.sum { |provision| provision.provision_value.to_f }
        provisions_by_year[year] = { provisions: provisions_in_year, sum: sum_of_values }
      end

      # Compute total sum for the category
      total_category_sum = provisions.sum { |provision| provision.provision_value.to_f }

      # Replace category data with subgroups and total sum
      grouped_data[category] = { years: provisions_by_year, total_sum: total_category_sum }
    end

    grouped_data
  end

  def self.grouped_by_year
    provisions = where.not(provision_year: nil) # Get all provisions where provision_year is not nil
    # Calculate total sum of all provisions, regardless of category
    total_sum = provisions.sum { |provision| provision.provision_value.to_f }
    # Group provisions by year
    provisions_by_year = provisions.group_by { |provision| provision.provision_year }
    # Calculate sum for each year
    provisions_by_year.each do |year, provisions_in_year|
      sum_of_values = provisions_in_year.sum { |provision| provision.provision_value.to_f }
      provisions_by_year[year] = { provisions: provisions_in_year, sum: sum_of_values }
    end
    # Return the grouped data
    {
      total_sum: total_sum,
      provisions_by_year: provisions_by_year
    }
  end
end
