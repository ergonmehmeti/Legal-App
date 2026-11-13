module Admin
  class DashboardController < BaseController
    def index
      @users_count = User.count
      @inactive_users_count = User.inactive_users.count
      @users_by_role = User.group(:role).count
      @deleted_lawsuits_count = Lawsuit.discarded.count
      @courts_count = Court.count
      @inactive_courts_count = Court.where(active: false).count
    end
  end
end
