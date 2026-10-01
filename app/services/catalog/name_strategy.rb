module Catalog
  class NameStrategy
    def call(scope, query)
      return scope if query.blank?
      scope.where("name ILIKE ?", "%#{Product.sanitize_sql_like(query)}%")
    end
  end
end
