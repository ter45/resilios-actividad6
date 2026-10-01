def cat(code)
  Category.find_by!(code: code)
end

PRODUCT_DATA = [
  { name: "Arroz Diana 500g",               sku: "ARR-DIA-500", barcode: "7702001100100", category: "ABA", cost: 2200, price: 3200, stock: 60, tax_rate: 0.0,  pricing_mode: :unit },
  { name: "Arroz Diana 1kg",                sku: "ARR-DIA-1000", barcode: "7702001100101", category: "ABA", cost: 4200, price: 5800, stock: 40, tax_rate: 0.0,  pricing_mode: :unit },
  { name: "Aceite Premier 1L",              sku: "ACE-PRE-1L",  barcode: "7702001200100", category: "ABA", cost: 8500, price: 11500, stock: 25, tax_rate: 0.19, pricing_mode: :unit },
  { name: "Azucar refinada 1kg",            sku: "AZU-REF-1KG", barcode: "7702001300100", category: "ABA", cost: 3800, price: 5200, stock: 30, tax_rate: 0.0,  pricing_mode: :unit },
  { name: "Sal refinada 500g",              sku: "SAL-REF-500", barcode: "7702001400100", category: "ABA", cost: 1200, price: 1800, stock: 50, tax_rate: 0.0,  pricing_mode: :unit },
  { name: "Frijol bola roja 500g",          sku: "FRI-BOL-500", category: "ABA", cost: 4500, price: 6500, stock: 20, tax_rate: 0.0,  pricing_mode: :unit },
  { name: "Lentejas 500g",                  sku: "LEN-500",     category: "ABA", cost: 3200, price: 4800, stock: 22, tax_rate: 0.0,  pricing_mode: :unit },
  { name: "Pasta La Muneca 500g",           sku: "PAS-MUN-500", barcode: "7702001500100", category: "ABA", cost: 2800, price: 4200, stock: 35, tax_rate: 0.19, pricing_mode: :unit },
  { name: "Leche entera Alpina 1L",         sku: "LEC-ALP-ENT", barcode: "7702011000123", category: "LAC", cost: 3500, price: 4800, stock: 30, tax_rate: 0.0,  pricing_mode: :unit },
  { name: "Leche deslactosada Alpina 1L",   sku: "LEC-ALP-DES", barcode: "7702011000130", category: "LAC", cost: 3800, price: 5300, stock: 18, tax_rate: 0.0,  pricing_mode: :unit },
  { name: "Yogurt Alpina vaso 200g",        sku: "YOG-ALP-200", barcode: "7702011100200", category: "LAC", cost: 1500, price: 2300, stock: 40, tax_rate: 0.19, pricing_mode: :unit },
  { name: "Queso campesino 500g",           sku: "QUE-CAM-500", category: "LAC", cost: 8500, price: 12000, stock: 10, tax_rate: 0.0,  pricing_mode: :unit },
  { name: "Queso doble crema",              category: "LAC", cost: 18000, price: 26000, stock: 4.5, tax_rate: 0.0, pricing_mode: :weight },
  { name: "Mantequilla Alpina 250g",        sku: "MAN-ALP-250", barcode: "7702011200100", category: "LAC", cost: 4500, price: 6500, stock: 15, tax_rate: 0.19, pricing_mode: :unit },
  { name: "Carne de res molida",            category: "CAR", cost: 16000, price: 22000, stock: 8.0, tax_rate: 0.0, pricing_mode: :weight },
  { name: "Pechuga de pollo",               category: "CAR", cost: 12000, price: 17000, stock: 12.5, tax_rate: 0.0, pricing_mode: :weight },
  { name: "Costilla de cerdo",              category: "CAR", cost: 15000, price: 21000, stock: 6.0, tax_rate: 0.0, pricing_mode: :weight },
  { name: "Salchicha Zenu paquete",         sku: "SAL-ZEN-PAQ", barcode: "7702012000100", category: "CAR", cost: 6500, price: 9500, stock: 20, tax_rate: 0.19, pricing_mode: :unit },
  { name: "Tomate chonto",                  category: "FRU", cost: 2500, price: 4000, stock: 15.5, tax_rate: 0.0, pricing_mode: :weight },
  { name: "Cebolla cabezona",               category: "FRU", cost: 1800, price: 3000, stock: 18.0, tax_rate: 0.0, pricing_mode: :weight },
  { name: "Banano",                         category: "FRU", cost: 1500, price: 2800, stock: 22.0, tax_rate: 0.0, pricing_mode: :weight },
  { name: "Manzana roja",                   category: "FRU", cost: 4500, price: 7500, stock: 10.0, tax_rate: 0.0, pricing_mode: :weight },
  { name: "Limon Tahiti",                   category: "FRU", cost: 2000, price: 3500, stock: 8.5, tax_rate: 0.0, pricing_mode: :weight },
  { name: "Papa pastusa",                   category: "VER", cost: 1200, price: 2200, stock: 30.0, tax_rate: 0.0, pricing_mode: :weight },
  { name: "Zanahoria",                      category: "VER", cost: 1500, price: 2800, stock: 12.0, tax_rate: 0.0, pricing_mode: :weight },
  { name: "Lechuga crespa unidad",          sku: "LEC-CRE-UND", category: "VER", cost: 1500, price: 2500, stock: 20, tax_rate: 0.0, pricing_mode: :unit },
  { name: "Coca-Cola 350ml",                sku: "COC-350", barcode: "7702004001234", category: "BEB", cost: 1800, price: 2500, stock: 60, tax_rate: 0.19, pricing_mode: :unit },
  { name: "Coca-Cola 1.5L",                 sku: "COC-1500", barcode: "7702004001500", category: "BEB", cost: 4500, price: 6500, stock: 25, tax_rate: 0.19, pricing_mode: :unit },
  { name: "Postobon manzana 350ml",         sku: "POS-MAN-350", barcode: "7702004002000", category: "BEB", cost: 1700, price: 2400, stock: 30, tax_rate: 0.19, pricing_mode: :unit },
  { name: "Agua Cristal 600ml",             sku: "AGU-CRI-600", barcode: "7702004003000", category: "BEB", cost: 1200, price: 2000, stock: 50, tax_rate: 0.19, pricing_mode: :unit },
  { name: "Cerveza Aguila lata 330ml",      sku: "CER-AGU-LAT", barcode: "7702004004000", category: "BEB", cost: 2800, price: 3800, stock: 36, tax_rate: 0.19, pricing_mode: :unit },
  { name: "Pan tajado Bimbo grande",        sku: "PAN-BIM-GRA", barcode: "7702005001000", category: "PAN", cost: 4200, price: 6200, stock: 15, tax_rate: 0.0,  pricing_mode: :unit },
  { name: "Galletas Saltinas Noel",         sku: "GAL-NOE-SAL", barcode: "7702005002000", category: "PAN", cost: 2200, price: 3200, stock: 40, tax_rate: 0.19, pricing_mode: :unit },
  { name: "Jabon Rey panela",               sku: "JAB-REY-PAN", barcode: "7702006001000", category: "ASE", cost: 2200, price: 3500, stock: 30, tax_rate: 0.19, pricing_mode: :unit },
  { name: "Detergente Fab 500g",            sku: "DET-FAB-500", barcode: "7702006002000", category: "ASE", cost: 4500, price: 6800, stock: 22, tax_rate: 0.19, pricing_mode: :unit },
  { name: "Papel higienico Familia x4",     sku: "PAP-FAM-X4",  barcode: "7702006003000", category: "ASE", cost: 5500, price: 8200, stock: 28, tax_rate: 0.19, pricing_mode: :unit },
  { name: "Papitas Margarita 35g",          sku: "PAP-MAR-35",  barcode: "7702007001000", category: "SNA", cost: 1500, price: 2200, stock: 50, tax_rate: 0.19, pricing_mode: :unit },
  { name: "Chocoramo unidad",               sku: "CHO-RAM-UND", barcode: "7702007002000", category: "SNA", cost: 1500, price: 2300, stock: 45, tax_rate: 0.19, pricing_mode: :unit }
]

puts "Cargando productos..."
created = 0
skipped = 0

PRODUCT_DATA.each do |attrs|
  attrs = attrs.dup
  category_code = attrs.delete(:category)
  attrs[:category] = cat(category_code)

  product = Product.find_or_initialize_by(name: attrs[:name])
  if product.persisted?
    skipped += 1
    next
  end

  product.assign_attributes(attrs)
  product.save!
  created += 1
end

puts "  Creados: #{created} | Ya existian: #{skipped}"
puts "  Total productos en base: #{Product.kept.count}"
