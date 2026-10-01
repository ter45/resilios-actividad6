module Catalog
  class CodeStrategy
    def call(scope, query)
      scope.where("sku = :sku OR barcode = :barcode", sku: query.upcase, barcode: query)
    end
  end
end
