module Pos
  class HomeController < ApplicationController
    layout "pos"
    before_action :ensure_can_sell

    def index
    end

    private

    def ensure_can_sell
      unless current_user.can_sell?
        redirect_to admin_root_path, alert: "Acceso solo para cajeros."
      end
    end
  end
end
