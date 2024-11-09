class LawsuitsController < ApplicationController
  #before_action :set_lawsuit, only: [:show, :edit, :update, :destroy]
  def index
    @category = params[:category] || Lawsuit.categories.keys.first
    @lawsuits = Lawsuit.where(category: @category)
  end

  def show
    @category = params[:category] || Lawsuit.categories.first
    @lawsuit = Lawsuit.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to filtered_lawsuits_path(category: @category)
  end

  def new
    @lawsuit = Lawsuit.new
  end

  def create
    @lawsuit = Lawsuit.new(lawsuit_params)
    if @lawsuit.save
      redirect_to show_lawsuits_path( category: @lawsuit.category, id: @lawsuit.id)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @lawsuit = Lawsuit.find(params[:id])
  end

  def update
    @lawsuit = Lawsuit.find(params[:id])
    if @lawsuit.update(lawsuit_params)
      redirect_to show_lawsuits_path( category: @lawsuit.category, id: @lawsuit.id)
    else
      render :edit, status: :unprocessable_entity
    end
  end
  def destroy
    @lawsuit = Lawsuit.find(params[:id])
    @category = @lawsuit.category
    if @lawsuit.destroy
      flash[:notice] = "Lawsuit was successfully deleted."
      redirect_to filtered_lawsuits_path(category: @category)
    else
      flash[:alert] = "Failed to delete the lawsuit."
      redirect_to show_lawsuits_path(category: @lawsuit.category, id: @lawsuit.id)

    end


  end


  private
  def lawsuit_params
    params.require(:lawsuit).permit(:title, :category, :status, :description, :context_type, :plaintiff, :lawsuit_claim, :lawsuit_number)
  end
end
