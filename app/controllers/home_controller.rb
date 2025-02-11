class HomeController < ApplicationController
  def index
    @categories = Lawsuit.categories.keys
    @chart_data = @categories.map do |category|
      {
        name: category.titleize,
        data: Lawsuit.where(category: category)
                     .group(:status)
                     .count
                     .transform_keys { |key| Lawsuit.new(status: key).enum_value(:status) },
        value: category

      }
    end
  end
end