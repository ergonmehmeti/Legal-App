class LawsuitsController < ApplicationController
  #before_action :set_lawsuit, only: [:show, :edit, :update, :destroy]
  def index
    @category = params[:category] || Lawsuit.categories.keys.first
    @lawsuits = Lawsuit.important_lawsuits(@category)
    # Apply filtering based on search parameters
    if params[:plaintiff].present? || params[:lawsuit_number].present? || params[:status].present?
      @lawsuits = Lawsuit.filter_by_params(@category, params)
    end

    @lawsuits = @lawsuits.paginate(page: params[:page], per_page: 10)


    respond_to do |format|
      format.html  # Renders the full page (not needed for Turbo requests)
      format.turbo_stream  # Handles the Turbo Stream response
    end

  end

  def show
    @category = params[:category] || Lawsuit.categories.first
    @lawsuit = Lawsuit.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to filtered_lawsuits_path(category: @category)
  end

  def new
    @lawsuit = Lawsuit.new(category: params[:category])
    @lawsuit.comments.build
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
    @lawsuit.comments.build
  end

  def update
    @lawsuit = Lawsuit.find(params[:id])
    authorize @lawsuit
    if lawsuit_params[:pdf_files]
      @lawsuit.pdf_files.attach(lawsuit_params[:pdf_files])
    end
    if @lawsuit.update(lawsuit_params.except(:pdf_files))
      redirect_to show_lawsuits_path( category: @lawsuit.category, id: @lawsuit.id)
    else
      render :edit, status: :unprocessable_entity
    end
  end
  def destroy
    @lawsuit = Lawsuit.find(params[:id])
    authorize @lawsuit
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
    params.require(:lawsuit).permit(:title, :category, :status, :description, :context_type, :plaintiff, :lawsuit_claim, :lawsuit_number, :court,
                                    :lawsuit_amount_claim, :lawsuit_risk, :provision, :lawsuit_state, :lawsuit_development_procedure, :civil_lawsuit,
                                    :institution, :lawsuit_phase_procedure,
                                    comments_attributes: [ :id, :content, :user_id ], pdf_files: [])
  end
end
