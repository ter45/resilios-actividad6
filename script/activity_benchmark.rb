require_relative '../test/test_helper'
class ActivityBenchmarkTest < ActionDispatch::IntegrationTest
  test 'catalog benchmark' do
require "json"
require "fileutils"
abort "Solo test" unless Rails.env.test? && ActiveRecord::Base.connection_db_config.configuration_hash[:port].to_i == 55436
abort "La base del benchmark debe estar vacia; usar una base de laboratorio nueva" if Product.exists?
variant = ENV.fetch("ACTIVITY_VARIANT", "baseline")
results = []
[100, 1000, 10000].each do |size|
  ActiveRecord::Base.transaction(requires_new: true) do
    user = User.create!(name: "Activity Cashier", email: "activity@example.test", password: "password123", role: :cashier, terminal_assigned: "A", active: true)
    categories = %w[Actividad-A Actividad-B].map { |name| Category.create!(name: name) }
    now = Time.current
    rows = size.times.map { |i| { name: "Producto #{i.to_s.rjust(6, '0')}", sku: "ACT-#{i}", category_id: categories[i % 2].id, price: 1000, cost: 500, stock: 100, tax_rate: 0, active: true, pricing_mode: 0, created_at: now, updated_at: now } }
    Product.insert_all!(rows)
    ids = Product.where(sku: rows.map { |r| r[:sku] }).order(:id).pluck(:id)
    StockReservation.insert_all!(ids.map { |id| { product_id: id, user_id: user.id, cart_id: "benchmark", terminal_id: "A", quantity: 1, expires_at: 1.hour.from_now, created_at: now, updated_at: now } })
    client = self
    client.post(user_session_path, params: { user: { email: user.email, password: "password123" } })
    assert_redirected_to pos_root_path
    queries = { "nombre" => { q: "Producto" }, "categoria_texto" => { q: "Producto", category_id: categories.first.id }, "codigo" => { q: "ACT-42" }, "sin_resultados" => { q: "NoExiste" } }
    queries.each do |label, params|
      samples = []
      sql_counts = []
      returned = []
      35.times do |iteration|
        count = 0
        subscriber = ->(*args) { payload = args.last; count += 1 unless payload[:name] == "SCHEMA" || payload[:cached] || payload[:sql].match?(/\A(?:BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)/) }
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
          ActiveRecord::Base.uncached { client.get("/pos/products/search", params: params, headers: { "ACCEPT" => "application/json" }) }
        end
        elapsed = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000
        raise "HTTP #{client.response.status}" unless client.response.status == 200
        body = JSON.parse(client.response.body)
        returned = body.is_a?(Array) ? body : body.fetch("products")
        if iteration >= 5
          samples << elapsed
          sql_counts << count
        end
      end
      sorted = samples.sort
      entry = { variant: variant, catalog_size: size, case: label, repetitions: 30, warmup: 5, returned: returned.size, median_ms: ((sorted[14] + sorted[15]) / 2).round(3), p95_ms: sorted[28].round(3), sql_min: sql_counts.min, sql_max: sql_counts.max, wrong_category: label == "categoria_texto" ? returned.count { |p| p["category_name"] != categories.first.name } : nil, samples_ms: samples.map { |x| x.round(3) } }
      results << entry
      puts entry.except(:samples_ms).to_json
    end
    reset!
    raise ActiveRecord::Rollback
  end
end
FileUtils.mkdir_p("evidence")
File.write("evidence/#{variant}.json", JSON.pretty_generate({ ruby: RUBY_VERSION, rails: Rails.version, environment: Rails.env, database: "PostgreSQL 17.11, isolated port 55436", page_size: 40, results: results }))

  end
end
