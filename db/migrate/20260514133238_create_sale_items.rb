class CreateSaleItems < ActiveRecord::Migration[8.1]
  def change
    create_table :sale_items do |t|
      t.references :sale,         null: false, foreign_key: true
      t.references :product,      null: false, foreign_key: true

      t.string  :product_name,    null: false
      t.string  :product_sku
      t.integer :pricing_mode,    null: false, default: 0

      t.decimal :quantity,        precision: 18, scale: 3, null: false
      t.decimal :unit_price,      precision: 18, scale: 2, null: false
      t.decimal :tax_rate,        precision: 5,  scale: 4, null: false, default: 0
      t.decimal :line_subtotal,   precision: 18, scale: 2, null: false
      t.decimal :line_tax,        precision: 18, scale: 2, null: false, default: 0
      t.decimal :line_total,      precision: 18, scale: 2, null: false

      t.integer :position,        null: false, default: 0

      t.timestamps
    end

    add_index :sale_items, [:sale_id, :position]
    add_index :sale_items, [:product_id, :created_at]
  end
end
