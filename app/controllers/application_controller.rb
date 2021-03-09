class ApplicationController < ActionController::Base
  include CurrentUserConcern
  skip_before_action :verify_authenticity_token

  def current_user
    @current_user
  end
  
  def user_signed_in?
    if current_user
      return true
    else
      return false
    end
  end

  def require_user
    if !user_signed_in?
      render json: {
        status: 401
      }
    end
  end

  def require_vendor
    if !current_user.vendor
      render json: {
        status: 401
      }
    end
  end
end
