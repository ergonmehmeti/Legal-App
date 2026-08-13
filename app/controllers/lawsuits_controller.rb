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
    @lawsuit = Lawsuit.kept.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to filtered_lawsuits_path(category: @category)
  end

  def new
    @lawsuit = Lawsuit.new(category: params[:category])
    @lawsuit.comments.build
    @lawsuit.provisions.build
  end

  def create
    @lawsuit = Lawsuit.new(lawsuit_params)
    if @lawsuit.save
      redirect_to show_lawsuits_path(category: @lawsuit.category, id: @lawsuit.id)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @lawsuit = Lawsuit.find(params[:id])
    @lawsuit.comments.build
    @lawsuit.provisions.build
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
    # SECURITY: Admin and admin_developer can delete lawsuits
    unless current_user.admin? || current_user.admin_developer?
      flash[:alert] = "Only Admins and Admin Developers can delete lawsuits."
      redirect_to root_path and return
    end
    
    @lawsuit = Lawsuit.kept.find(params[:id])
    authorize @lawsuit  # Double-check with Pundit policy
    @category = @lawsuit.category
    
    # Require deletion reason
    deletion_reason = params[:deletion_reason]
    if deletion_reason.blank?
      flash[:alert] = "Deletion reason is required."
      redirect_to show_lawsuits_path(category: @lawsuit.category, id: @lawsuit.id) and return
    end
    
    # Soft delete with audit trail
    @lawsuit.update(
      deletion_reason: deletion_reason,
      deleted_by_user_id: current_user.id,
      deleted_at: Time.current
    )
    
    if @lawsuit.discard
      flash[:notice] = "Lawsuit was successfully deleted (archived)."
      redirect_to filtered_lawsuits_path(category: @category)
    else
      flash[:alert] = "Failed to delete the lawsuit."
      redirect_to show_lawsuits_path(category: @lawsuit.category, id: @lawsuit.id)
    end
  end
  
  def deleted
    # SECURITY: Only admin_developer can view deleted lawsuits
    unless current_user.admin_developer?
      flash[:alert] = "Only Admin Developers can view deleted lawsuits."
      redirect_to root_path and return
    end
    
    authorize Lawsuit, :view_deleted?  # Double-check with Pundit policy
    
    @category = params[:category]
    @lawsuits = Lawsuit.discarded
    @lawsuits = @lawsuits.where(category: @category) if @category.present?
    @lawsuits = @lawsuits.order(discarded_at: :desc).paginate(page: params[:page], per_page: 10)
  end
  
  def restore
    # SECURITY: Only admin_developer can restore deleted lawsuits
    unless current_user.admin_developer?
      flash[:alert] = "Only Admin Developers can restore lawsuits."
      redirect_to root_path and return
    end
    
    @lawsuit = Lawsuit.discarded.find(params[:id])
    authorize @lawsuit, :view_deleted?  # Double-check with Pundit policy
    
    if @lawsuit.undiscard
      # Clear deletion tracking fields
      @lawsuit.update(deletion_reason: nil, deleted_by_user_id: nil, deleted_at: nil)
      flash[:notice] = "Lawsuit was successfully restored."
      redirect_to show_lawsuits_path(category: @lawsuit.category, id: @lawsuit.id)
    else
      flash[:alert] = "Failed to restore the lawsuit."
      redirect_to deleted_lawsuits_path(category: @lawsuit.category)
    end
  end
  
  def show_deleted
    # SECURITY: Only admin_developer can view deleted lawsuit details
    unless current_user.admin_developer?
      flash[:alert] = "Only Admin Developers can view deleted lawsuits."
      redirect_to root_path and return
    end
    
    @category = params[:category]
    @lawsuit = Lawsuit.discarded.find(params[:id])
    authorize @lawsuit, :view_deleted?  # Double-check with Pundit policy
  end


  private
  def lawsuit_params
    params.require(:lawsuit).permit(:title, :category, :status, :description, :context_type, :plaintiff, :lawsuit_claim, :lawsuit_number, :court,
                                    :lawsuit_amount_claim, :lawsuit_risk, :provision, :lawsuit_state, :lawsuit_development_procedure, :civil_lawsuit,
                                    :institution, :lawsuit_phase_procedure,
                                    pdf_files: [],
                                    comments_attributes: [ :id, :content, :user_id ],
                                    provisions_attributes: [ :id, :provision_value, :provision_year ])
          .tap do |whitelisted|
      whitelisted[:provisions_attributes]&.reject! { |_, p| (p[:provision_value].blank? || p[:provision_year].blank?) && false }
    end
  end

end
