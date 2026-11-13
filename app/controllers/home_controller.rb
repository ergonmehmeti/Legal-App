class HomeController < ApplicationController
  def index
    # Only lawsuits the user may see (legal representative: their own), without archived ones
    lawsuits = policy_scope(Lawsuit).kept
    # Legal representative: only categories in which they have lawsuits
    @categories = visible_categories.keys
    @chart_data = @categories.map do |category|
      {
        name: category.titleize,
        data: lawsuits.where(category: category)
                     .group(:status)
                     .count
                     .transform_keys { |key| Lawsuit.new(status: key).enum_value(:status) },
        value: category

      }
    end
    return unless current_user.legal_representative?

    # Legal representative's Kryefaqja has two separate parts:
    # 1. "Lëndët e mia": lawsuits they are assigned to (as representative), per category
    own = Lawsuit.kept.represented_by(current_user)
    @own_counts = own.group(:category).count
    @own_categories = Lawsuit.categories.select { |key, _| @own_counts.key?(key) }
    # 2. Categories an admin gave them full (read only) access to: ALL lawsuits there
    @scope_categories = Lawsuit.categories.select { |key, _| current_user.category_scopes.include?(key) }
    @scope_counts = Lawsuit.kept.where(category: @scope_categories.keys).group(:category).count
  end
end
