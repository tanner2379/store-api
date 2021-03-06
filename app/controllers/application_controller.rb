class ApplicationController < ActionController::API
  include ActionController::Cookies
  include ActionController::RequestForgeryProtection
  before_action :set_csrf_cookie
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token

  private

  def set_csrf_cookie
    cookies["CSRF-TOKEN"] = form_authenticity_token
  end

end