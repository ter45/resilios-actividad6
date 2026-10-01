module Admin
  class DashboardController < ApplicationController
    layout "admin"

    def index
      @data = Dashboard::Compute.call
      @setting = Setting.current
    end
  end
end
