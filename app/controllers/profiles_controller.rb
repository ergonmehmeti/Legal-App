# Every logged-in user can change their OWN password here.
# Needs the current password; the new one must be min 8 characters (see User model).
class ProfilesController < ApplicationController
  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if password_params[:password].blank?
      @user.errors.add(:password, "i ri nuk mund të jetë bosh")
      return render :edit, status: :unprocessable_entity
    end

    # Devise: checks current_password, then saves the new password
    if @user.update_with_password(password_params)
      # Changing the password would otherwise log the user out
      bypass_sign_in(@user)
      redirect_to root_path, notice: "Fjalëkalimi u ndryshua me sukses."
    else
      @user.clean_up_passwords
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end
end
