module Admin
  class ProductsController < ApplicationController
    layout "admin"

    before_action :set_product, only: %i[show edit update destroy toggle_active]

    def index
      @categories = Category.kept.active.ordered
      @scope = policy_scope(Product).includes(:category)

      @scope = @scope.where(category_id: params[:category_id]) if params[:category_id].present?
      @scope = @scope.search(params[:q]) if params[:q].present?

      @products = @scope.ordered.page_size_limited
      authorize Product
    end

    def show
      authorize @product
    end

    def new
      @product = Product.new(active: true, pricing_mode: :unit, tax_rate: 0.19, stock: 0, cost: 0, price: 0)
      authorize @product
    end

    def create
      @product = Product.new(product_params)
      authorize @product

      if @product.save
        redirect_to admin_products_path, notice: "Producto \"#{@product.name}\" creado."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @product
    end

    def update
      authorize @product

      if @product.update(product_params)
        redirect_to admin_products_path, notice: "Producto \"#{@product.name}\" actualizado."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @product

      @product.discard
      redirect_to admin_products_path, notice: "Producto \"#{@product.name}\" eliminado."
    end

    def toggle_active
      authorize @product, :toggle_active?

      @product.update!(active: !@product.active)
      estado = @product.active? ? "activado" : "desactivado"
      redirect_to admin_products_path, notice: "Producto \"#{@product.name}\" #{estado}."
    end

    private

    def set_product
      @product = Product.find(params[:id])
    end

    def product_params
      params.expect(product: [:name, :sku, :barcode, :category_id, :cost, :price, :stock, :tax_rate, :pricing_mode, :active])
    end
  end
end
