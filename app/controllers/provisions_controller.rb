class ProvisionsController < ApplicationController
  def index
    @grouped_by_category = Provision.grouped_by_category_and_year
    @grouped_by_year = Provision.grouped_by_year
    render "provisions /index"
  end
  def create
    @provision = Provision.new(provision_params)
    if @provision.save
      redirect_to show_lawsuits_path(category: @provision.lawsuit.category, id: @provision.lawsuit_id)
    end
  end

  private
  def provision_params
    params.require(:provision).permit(:provision_value, :provision_year, :lawsuit_id)
  end
end
