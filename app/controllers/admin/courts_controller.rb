# Courts ("Gjykatat") in the Admin area: admin_developer only (Admin::BaseController).
# Add, rename, change order, (de)activate. No delete (see Court, TODO_COURTS.md).
module Admin
  class CourtsController < BaseController
    before_action :set_court, only: %i[edit update toggle_active]

    def index
      @courts = Court.ordered
      # Lawsuits per court name (also archived ones, capitals ignored), one query
      @lawsuit_counts = Lawsuit.with_discarded.where.not(court: nil).group("LOWER(court)").count
    end

    def new
      # New courts go to the end of the list by default
      @court = Court.new(position: Court.maximum(:position).to_i + 10)
    end

    def create
      @court = Court.new(court_params)
      if @court.save
        redirect_to admin_courts_path, notice: "Gjykata \"#{@court.name}\" u shtua."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      old_name = @court.name
      if @court.update(court_params)
        notice = "Gjykata \"#{@court.name}\" u përditësua."
        if @court.name != old_name
          renamed = @court.lawsuits_count
          notice += " Emri u ndryshua edhe në #{renamed} lëndë."
        end
        redirect_to admin_courts_path, notice: notice
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def toggle_active
      # update_attribute: keeps callbacks, so PaperTrail records who (de)activated it
      @court.update_attribute(:active, !@court.active?)
      status = @court.active? ? "u aktivizua" : "u çaktivizua"
      redirect_to admin_courts_path, notice: "Gjykata \"#{@court.name}\" #{status}."
    end

    private

    def set_court
      @court = Court.find(params[:id])
    end

    def court_params
      params.require(:court).permit(:name, :position)
    end
  end
end
