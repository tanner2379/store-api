class RegistrationsController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  def create
    user = User.create!(user_params);

    if user
      session[:user_id] = user.id
      render json: {
        status: :created,
        user: user
      }
    else
      render json: {
        status: 500
      }
    end
  end

  def update
    if @user.update(user_params)
      render json: {
        status: :updated,
        user: @user
      }
    else
      render json: {
        status: 500
      }
    end
  end

  def destroy
    if @user.destroy
      render json: {
        status: :deleted
      }
    else
      render json: {
        status: 500
      }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end