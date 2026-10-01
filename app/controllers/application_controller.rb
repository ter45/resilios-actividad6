class ApplicationController < ActionController::Base
  include Pundit::Authorization

  allow_browser versions: :modern

  before_action :authenticate_user!

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def after_sign_in_path_for(resource)
    case resource.role
    when "admin", "supervisor", "viewer"
      admin_root_path
    when "cashier"
      pos_root_path
    else
      root_path
    end
  end

  private

  def user_not_authorized
    flash[:alert] = "No tienes permiso para realizar esa acción."
    redirect_back(fallback_location: root_path)
  end
end
