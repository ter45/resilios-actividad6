module Admin
  class CustomersController < ApplicationController
    layout "admin"

    before_action :set_customer, only: %i[show edit update destroy toggle_active]

    def index
      @scope = policy_scope(Customer)
      @scope = @scope.search(params[:q]) if params[:q].present?
      @scope = @scope.with_debt if params[:filter] == "with_debt"
      @scope = @scope.with_credit if params[:filter] == "with_credit"
      @customers = @scope.ordered.limit(100)
      authorize Customer
    end

    def show
      authorize @customer
    end

    def new
      @customer = Customer.new(active: true, document_type: :cc)
      authorize @customer
    end

    def create
      @customer = Customer.new(customer_params)
      authorize @customer

      if @customer.save
        redirect_to admin_customers_path, notice: "Cliente \"#{@customer.name}\" creado."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @customer
    end

    def update
      authorize @customer

      if @customer.update(customer_params)
        redirect_to admin_customers_path, notice: "Cliente \"#{@customer.name}\" actualizado."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @customer

      if @customer.in_debt?
        redirect_to admin_customers_path,
          alert: "No se puede eliminar \"#{@customer.name}\" porque tiene saldo pendiente de $#{@customer.credit_balance.to_i}."
        return
      end

      @customer.discard
      redirect_to admin_customers_path, notice: "Cliente \"#{@customer.name}\" eliminado."
    end

    def toggle_active
      authorize @customer, :toggle_active?

      @customer.update!(active: !@customer.active)
      estado = @customer.active? ? "activado" : "desactivado"
      redirect_to admin_customers_path, notice: "Cliente \"#{@customer.name}\" #{estado}."
    end

    private

    def set_customer
      @customer = Customer.find(params[:id])
    end

    def customer_params
      params.expect(customer: [
        :name, :document_type, :document_number, :phone, :address,
        :credit_limit, :active
      ])
    end
  end
end
