module Seeds
  class FarmCatalog
    CATEGORIES = {
      "AVES" => "Alimentos para aves", "BOV" => "Alimentos para bovinos",
      "POR" => "Alimentos para porcinos", "EQU" => "Alimentos para equinos",
      "OVC" => "Alimentos para ovinos y caprinos", "CUN" => "Alimentos para conejos",
      "GRA" => "Granos y forrajes", "ACC" => "Accesorios de granja"
    }.freeze

    # Catalogo inicial: sin marcas ni codigos de barras comerciales inventados.
    # Precios, costos y existencias sinteticos para probar el POS; no son cotizaciones.
    PRODUCTS = [
      ["AV-INI-40", "Alimento para pollitos inicio 40 kg", "AVES", :unit],
      ["AV-ENG-40", "Alimento para pollo engorde 40 kg", "AVES", :unit],
      ["AV-PON-40", "Alimento para gallinas ponedoras 40 kg", "AVES", :unit],
      ["AV-PON-KG", "Alimento para ponedoras a granel", "AVES", :weight],
      ["BO-LEC-40", "Alimento para vacas lecheras 40 kg", "BOV", :unit],
      ["BO-TER-40", "Alimento para terneros 40 kg", "BOV", :unit],
      ["BO-CEB-40", "Alimento para bovinos de ceba 40 kg", "BOV", :unit],
      ["PO-INI-40", "Alimento para lechones inicio 40 kg", "POR", :unit],
      ["PO-LEV-40", "Alimento para cerdos levante 40 kg", "POR", :unit],
      ["PO-CEB-40", "Alimento para cerdos ceba 40 kg", "POR", :unit],
      ["EQ-MAN-40", "Alimento para caballos mantenimiento 40 kg", "EQU", :unit],
      ["OC-MAN-40", "Alimento para ovinos y caprinos 40 kg", "OVC", :unit],
      ["CU-CON-40", "Alimento para conejos 40 kg", "CUN", :unit],
      ["GR-MAI-KG", "Maíz partido a granel", "GRA", :weight],
      ["GR-SAL-KG", "Salvado de trigo a granel", "GRA", :weight],
      ["GR-AVE-KG", "Avena en grano a granel", "GRA", :weight],
      ["GR-HEN-PAC", "Heno en paca", "GRA", :unit],
      ["AC-BEB-3L", "Bebedero para aves 3 litros", "ACC", :unit],
      ["AC-BEB-10L", "Bebedero para aves 10 litros", "ACC", :unit],
      ["AC-COM-5K", "Comedero para aves 5 kg", "ACC", :unit],
      ["AC-COM-12K", "Comedero para aves 12 kg", "ACC", :unit],
      ["AC-CHU-POR", "Chupo bebedero para porcinos", "ACC", :unit],
      ["AC-BAL-12L", "Balde ganadero 12 litros", "ACC", :unit],
      ["AC-CAB-EQU", "Cabestro para equinos", "ACC", :unit],
      ["AC-LAZ-10M", "Lazo ganadero 10 metros", "ACC", :unit],
      ["AC-CEP-EQU", "Cepillo para equinos", "ACC", :unit]
    ].freeze

    LEGACY_PRODUCTS = [
      ["Arroz Diana 500g", "ARR-DIA-500"],
      ["Arroz Diana 1kg", "ARR-DIA-1000"],
      ["Aceite Premier 1L", "ACE-PRE-1L"],
      ["Azucar refinada 1kg", "AZU-REF-1KG"],
      ["Sal refinada 500g", "SAL-REF-500"],
      ["Frijol bola roja 500g", "FRI-BOL-500"],
      ["Lentejas 500g", "LEN-500"],
      ["Pasta La Muneca 500g", "PAS-MUN-500"],
      ["Leche entera Alpina 1L", "LEC-ALP-ENT"],
      ["Leche deslactosada Alpina 1L", "LEC-ALP-DES"],
      ["Yogurt Alpina vaso 200g", "YOG-ALP-200"],
      ["Queso campesino 500g", "QUE-CAM-500"],
      ["Queso doble crema", nil],
      ["Mantequilla Alpina 250g", "MAN-ALP-250"],
      ["Carne de res molida", nil],
      ["Pechuga de pollo", nil],
      ["Costilla de cerdo", nil],
      ["Salchicha Zenu paquete", "SAL-ZEN-PAQ"],
      ["Tomate chonto", nil],
      ["Cebolla cabezona", nil],
      ["Banano", nil],
      ["Manzana roja", nil],
      ["Limon Tahiti", nil],
      ["Papa pastusa", nil],
      ["Zanahoria", nil],
      ["Lechuga crespa unidad", "LEC-CRE-UND"],
      ["Coca-Cola 350ml", "COC-350"],
      ["Coca-Cola 1.5L", "COC-1500"],
      ["Postobon manzana 350ml", "POS-MAN-350"],
      ["Agua Cristal 600ml", "AGU-CRI-600"],
      ["Cerveza Aguila lata 330ml", "CER-AGU-LAT"],
      ["Pan tajado Bimbo grande", "PAN-BIM-GRA"],
      ["Galletas Saltinas Noel", "GAL-NOE-SAL"],
      ["Jabon Rey panela", "JAB-REY-PAN"],
      ["Detergente Fab 500g", "DET-FAB-500"],
      ["Papel higienico Familia x4", "PAP-FAM-X4"],
      ["Papitas Margarita 35g", "PAP-MAR-35"],
      ["Chocoramo unidad", "CHO-RAM-UND"],
    ].freeze

    DEMO_PRICES = {
      "AV-INI-40" => 95000, "AV-ENG-40" => 90000, "AV-PON-40" => 85000,
      "AV-PON-KG" => 2500, "BO-LEC-40" => 80000, "BO-TER-40" => 92000,
      "BO-CEB-40" => 78000, "PO-INI-40" => 110000, "PO-LEV-40" => 88000,
      "PO-CEB-40" => 84000, "EQ-MAN-40" => 96000, "OC-MAN-40" => 82000,
      "CU-CON-40" => 89000, "GR-MAI-KG" => 2200, "GR-SAL-KG" => 1800,
      "GR-AVE-KG" => 3000, "GR-HEN-PAC" => 25000, "AC-BEB-3L" => 15000,
      "AC-BEB-10L" => 35000, "AC-COM-5K" => 28000, "AC-COM-12K" => 48000,
      "AC-CHU-POR" => 18000, "AC-BAL-12L" => 22000, "AC-CAB-EQU" => 32000,
      "AC-LAZ-10M" => 28000, "AC-CEP-EQU" => 12000
    }.freeze

    def self.call
      ActiveRecord::Base.transaction do
        LEGACY_PRODUCTS.each do |name, sku|
          Product.where(name: name, sku: sku).update_all(active: false, updated_at: Time.current)
        end
        Category.where(code: %w[ABA LAC CAR FRU VER BEB PAN ASE SNA OTR]).each do |category|
          category.update!(active: false) unless Product.sellable.where(category: category).exists?
        end
        CATEGORIES.each_with_index do |(code, name), index|
          Category.find_or_create_by!(code: code) do |category|
            category.assign_attributes(name: name, position: index + 1, active: true)
          end
        end
        PRODUCTS.each do |sku, name, category_code, mode|
          product = Product.find_or_initialize_by(sku: sku)
          if product.new_record?
            product.assign_attributes(name: name, category: Category.find_by!(code: category_code),
              pricing_mode: mode, cost: 0, price: 0, stock: 0, tax_rate: 0, active: true)
          end
          # Completar solo los registros vacios del seed anterior. No reponer
          # productos agotados ni sobrescribir datos comerciales ya configurados.
          if product.price.zero? && product.cost.zero? && product.stock.zero?
            price = DEMO_PRICES.fetch(sku)
            product.assign_attributes(price: price, cost: price * 0.75,
              stock: mode == :weight ? 100 : 20)
          end
          product.save! if product.new_record? || product.changed?
        end
      end
    end
  end
end