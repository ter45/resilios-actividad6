module Catalog
  class Navigation
    PAGE_SIZE = 40
    Result = Data.define(:products, :page, :has_more, :strategy)

    def initialize(query: nil, category_id: nil, page: nil)
      @query = query.to_s.strip
      @category_id = category_id.presence
      @page = [page.to_i, 1].max
    end

    def call
      scope = Product.sellable
      scope = scope.where(category_id: @category_id) if @category_id
      code = CodeStrategy.new
      strategy = @query.present? && code.call(scope, @query).exists? ? code : NameStrategy.new
      rows = strategy.call(scope, @query).order(:name, :id)
        .offset((@page - 1) * PAGE_SIZE).limit(PAGE_SIZE + 1).includes(:category).to_a
      Result.new(products: rows.first(PAGE_SIZE), page: @page,
        has_more: rows.size > PAGE_SIZE, strategy: strategy.is_a?(CodeStrategy) ? "code" : "name")
    end
  end
end
