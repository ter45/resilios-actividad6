module Admin
  class SettingsController < ApplicationController
    layout "admin"

    def edit
      @setting = Setting.current
      authorize @setting
    end

    def update
      @setting = Setting.current
      authorize @setting

      if @setting.update(setting_params)
        redirect_to edit_admin_setting_path, notice: "Configuración actualizada."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def setting_params
      params.expect(setting: [
        :business_name, :legal_name, :nit, :address, :phone, :city,
        :ticket_header, :ticket_footer, :print_barcode, :paper_width_mm, :logo
      ]).reject { |key, value| key == "logo" && value.blank? }
    end
  end
end
