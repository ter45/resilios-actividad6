require Rails.root.join("db/seeds/farm_catalog")
Seeds::FarmCatalog.call
puts "Categorias de granja: #{Category.where(code: Seeds::FarmCatalog::CATEGORIES.keys).count}"
puts "Productos de granja: #{Product.where(sku: Seeds::FarmCatalog::PRODUCTS.map(&:first)).count}"
puts "Productos activos: #{Product.sellable.count}"
puts "Logo configurado: #{Setting.current.logo.attached?}"