class LawsuitsController < ApplicationController
  #before_action :set_lawsuit, only: [:show, :edit, :update, :destroy]
  def index
    @category = params[:category] || visible_categories.keys.first
    # A legal representative only opens categories in which they have lawsuits
    unless visible_categories.key?(@category)
      return redirect_to root_path, alert: "Nuk keni qasje në këtë kategori."
    end

    # policy_scope: a legal representative only gets their own lawsuits
    lawsuits = policy_scope(Lawsuit)
    @lawsuits = lawsuits.important_lawsuits(@category)
    # Apply filtering based on search parameters
    if params[:tk_number].present? || params[:plaintiff].present? || params[:lawsuit_number].present? || params[:status].present?
      @lawsuits = lawsuits.filter_by_params(@category, params)
    end

    @lawsuits = @lawsuits.preload(lawsuit_representatives: :user).paginate(page: params[:page], per_page: 10)


    respond_to do |format|
      format.html  # Renders the full page (not needed for Turbo requests)
      format.turbo_stream  # Handles the Turbo Stream response
    end

  end

  # "Lëndët e Mia": every (non-archived) lawsuit where the current user is a representative
  # (primary or secondary), across all categories, with an extra "Kategoria" filter.
  def mine
    authorize Lawsuit, :mine?

    my_lawsuits = Lawsuit.kept.represented_by(current_user)
    # Category filter: only the categories in which the user has lawsuits
    used = my_lawsuits.distinct.pluck(:category)
    @my_categories = Lawsuit.categories.select { |key, _| used.include?(key) }
    @has_lawsuits = used.any?

    # One category chosen: the table behaves like that category's page (column names, Gjykata).
    # nil = "Të gjitha" (mixed categories, the table shows a "Kategoria" column)
    @category = @my_categories.key?(params[:category]) ? params[:category] : nil
    # Same filters as the category pages (status empty = "Kryesoret": active + pending)
    @lawsuits = my_lawsuits.filter_by_params(@category || @my_categories.keys, params)
                           .preload(lawsuit_representatives: :user)
                           .paginate(page: params[:page], per_page: 10)
  end

  def show
    @category = params[:category] || Lawsuit.categories.first
    # Someone else's lawsuit is treated like a missing one (no hint that it exists)
    @lawsuit = policy_scope(Lawsuit).kept.find(params[:id])
    authorize @lawsuit
  rescue ActiveRecord::RecordNotFound
    redirect_to filtered_lawsuits_path(category: @category)
  end

  def new
    authorize Lawsuit, :create?
    @lawsuit = Lawsuit.new(category: params[:category])
    @lawsuit.comments.build
    @lawsuit.provisions.build
  end

  def create
    authorize Lawsuit, :create?
    @lawsuit = Lawsuit.new(lawsuit_params)
    if @lawsuit.save
      save_representatives
      redirect_to show_lawsuits_path(category: @lawsuit.category, id: @lawsuit.id)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Archived (deleted) lawsuits cannot be edited, not even by typing the URL
    @lawsuit = Lawsuit.kept.find_by(id: params[:id])
    return redirect_archived_lawsuit unless @lawsuit
    # Only roles that can save changes may open the edit page (same rule as update)
    authorize @lawsuit, :update?

    @lawsuit.comments.build
    @lawsuit.provisions.build
  end

  def update
    @lawsuit = Lawsuit.kept.find_by(id: params[:id])
    return redirect_archived_lawsuit unless @lawsuit

    authorize @lawsuit
    if lawsuit_params[:pdf_files]
      @lawsuit.pdf_files.attach(lawsuit_params[:pdf_files])
    end
    if @lawsuit.update(lawsuit_params.except(:pdf_files))
      save_representatives
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

  # Representatives from the lawsuit form ("Përfaqësuesi kryesor" + "Përfaqësues të tjerë").
  # Only for roles that may assign them, and only if the form actually sent the field:
  # a form without it (e.g. the operator's create form) leaves the assignments untouched.
  def save_representatives
    return unless policy(@lawsuit).assign_representatives?
    return unless params[:lawsuit]&.key?(:primary_representative_id)

    reps = params.require(:lawsuit).permit(:primary_representative_id, secondary_representative_ids: [])
    @lawsuit.assign_representatives!(
      primary_id: reps[:primary_representative_id],
      secondary_ids: reps[:secondary_representative_ids]
    )
  rescue ActiveRecord::RecordInvalid => e
    flash[:alert] = "Përfaqësuesit nuk u ruajtën: #{e.record.errors.full_messages.to_sentence}"
  rescue ActiveRecord::RecordNotUnique
    # Two saves at the same moment (double click, or two admins): the database allows one primary
    # per lawsuit, so the second one is refused. Nothing half-saved (assign_representatives! is one transaction).
    flash[:alert] = "Përfaqësuesit nuk u ruajtën: lënda u ruajt njëkohësisht dy herë. " \
                    "Kontrolloni përfaqësuesit dhe provoni përsëri nëse duhet."
  end

  def redirect_archived_lawsuit
    redirect_to filtered_lawsuits_path(category: params[:category]),
                alert: "Kjo lëndë është fshirë dhe nuk mund të ndryshohet."
  end

  def lawsuit_params
    params.require(:lawsuit).permit(:title, :category, :status, :description, :context_type, :plaintiff, :lawsuit_claim, :lawsuit_number, :court,
                                    :lawsuit_amount_claim, :lawsuit_risk, :provision, :lawsuit_state, :lawsuit_development_procedure, :civil_lawsuit,
                                    :institution, :lawsuit_phase_procedure, :final_status,
                                    pdf_files: [],
                                    comments_attributes: [ :id, :content, :user_id ],
                                    provisions_attributes: [ :id, :provision_value, :provision_year ])
          .tap do |whitelisted|
      whitelisted[:provisions_attributes]&.reject! { |_, p| (p[:provision_value].blank? || p[:provision_year].blank?) && false }
    end
  end

end
