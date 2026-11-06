module Admin
  class UsersController < BaseController
    before_action :set_user, only: %i[edit update]

    def index
      authorize User
      @users = User.order(:name, :surname)
    end

    def new
      @user = User.new(role: :operator)
      authorize @user
    end

    def create
      @user = User.new(user_params)
      authorize @user

      if @user.save
        redirect_to admin_users_path, notice: "Përdoruesi #{@user.name} #{@user.surname} u krijua me sukses."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      attrs = user_params
      # Blank password on edit = keep the current one
      attrs = attrs.except(:password, :password_confirmation) if attrs[:password].blank?
      @user.assign_attributes(attrs)

      # No lockout: you cannot remove your own admin_developer role
      if editing_self? && !@user.admin_developer?
        @user.errors.add(:base, "Nuk mund ta hiqni rolin Admin Developer nga llogaria juaj.")
        return render :edit, status: :unprocessable_entity
      end

      if @user.save
        # Changing your own password would otherwise log you out
        bypass_sign_in(@user) if editing_self? && attrs.key?(:password)
        redirect_to admin_users_path, notice: "Përdoruesi #{@user.name} #{@user.surname} u përditësua me sukses."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
      authorize @user
    end

    def editing_self?
      @user.id == current_user.id
    end

    def user_params
      params.require(:user).permit(:name, :surname, :email, :kt_id, :role, :password, :password_confirmation)
    end
  end
end
