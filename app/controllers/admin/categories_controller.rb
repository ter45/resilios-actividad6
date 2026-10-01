module Admin
  class CategoriesController < ApplicationController
    layout "admin"

    before_action :set_category, only: %i[show edit update destroy toggle_active]

    def index
      @categories = policy_scope(Category).ordered
      authorize Category
    end

    def show
      authorize @category
    end

    def new
      @category = Category.new(active: true, position: next_position)
      authorize @category
    end

    def create
      @category = Category.new(category_params)
      authorize @category

      if @category.save
        redirect_to admin_categories_path, notice: "Categoría \"#{@category.name}\" creada."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @category
    end

    def update
      authorize @category

      if @category.update(category_params)
        redirect_to admin_categories_path, notice: "Categoría \"#{@category.name}\" actualizada."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @category

      @category.discard
      redirect_to admin_categories_path, notice: "Categoría \"#{@category.name}\" eliminada."
    end

    def toggle_active
      authorize @category, :toggle_active?

      @category.toggle_active!
      estado = @category.active? ? "activada" : "desactivada"
      redirect_to admin_categories_path, notice: "Categoría \"#{@category.name}\" #{estado}."
    end

    private

    def set_category
      @category = Category.find(params[:id])
    end

    def category_params
      params.expect(category: [:name, :code, :position, :active])
    end

    def next_position
      (Category.maximum(:position) || 0) + 1
    end
  end
end
