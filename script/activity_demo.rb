abort "Solo base de laboratorio" unless Rails.env.test? && ActiveRecord::Base.connection_db_config.configuration_hash[:port].to_i == 55436
user = User.find_or_initialize_by(email: "demo.actividad6@example.test")
user.assign_attributes(name: "Demo Actividad 6", password: "DemoActividad6!", role: :cashier, terminal_assigned: "A", active: true)
user.save!
%w[Granos Forrajes].each do |name|
  category = Category.find_or_create_by!(name: name)
  85.times do |i|
    product = Product.find_or_initialize_by(sku: "DEMO-#{name.upcase}-#{i}")
    product.assign_attributes(name: "Alimento #{name} #{(i + 1).to_s.rjust(3, '0')}", category: category, stock: i == 0 ? 0 : 100, cost: 500, price: 1000, tax_rate: 0, active: true, pricing_mode: i.even? ? :unit : :weight)
    product.save!
  end
end
puts "Demo lista: 170 productos sinteticos, 2 categorias."
