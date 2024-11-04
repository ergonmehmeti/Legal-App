class LawsuitsController < ApplicationController
  #before_action :set_lawsuit, only: [:show, :edit, :update, :destroy]
  def index
    @category = params[:category] || Lawsuit.categories.keys.first
    @lawsuits = Lawsuit.where(category: @category)
  end
end
