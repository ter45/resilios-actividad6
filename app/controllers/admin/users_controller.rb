module Admin
  class UsersController < ApplicationController
    layout "admin"
    before_action :authorize_management
    before_action :set_user, only: %i[edit update]

    def index
      @users = policy_scope(User).order(:name, :id)
      if params[:q].present?
        query = "%#{User.sanitize_sql_like(params[:q].strip)}%"
        @users = @users.where("name ILIKE :q OR email ILIKE :q", q: query)
      end
      @users = @users.where(role: params[:role]) if User.roles.key?(params[:role])
      @users = @users.where(active: params[:active] == "1") if %w[0 1].include?(params[:active])
      @users = @users.limit(100)
    end

    def new
      @user = User.new(role: :cashier, active: true, terminal_assigned: "A")
    end

    def create
      @user = User.new(user_params)
      if @user.save
        redirect_to admin_users_path, notice: "Usuario creado correctamente."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      attributes = user_params
      if attributes[:password].blank? && attributes[:password_confirmation].blank?
        attributes = attributes.except(:password, :password_confirmation)
      end
      @user.assign_attributes(attributes)
      if @user == current_user && (!@user.admin? || !@user.active?)
        @user.errors.add(:base, "No puedes desactivar tu propia cuenta ni quitarte el rol de administrador.")
        render :edit, status: :unprocessable_entity
      elsif @user.save
        bypass_sign_in(@user) if @user == current_user
        redirect_to admin_users_path, notice: "Usuario actualizado correctamente."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def authorize_management
      authorize User, :index?
    end

    def set_user
      @user = policy_scope(User).find(params[:id])
    end

    def user_params
      params.expect(user: [:name, :email, :role, :terminal_assigned, :active, :password, :password_confirmation])
    end
  end
end
