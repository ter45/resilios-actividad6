class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string  :sku
      t.string  :barcode
      t.string  :name,         null: false
      t.references :category,  null: false, foreign_key: true

      t.decimal :cost,         precision: 18, scale: 2, null: false, default: 0
      t.decimal :price,        precision: 18, scale: 2, null: false, default: 0
      t.decimal :stock,        precision: 18, scale: 3, null: false, default: 0
      t.decimal :tax_rate,     precision: 5,  scale: 4, null: false, default: 0.19

      t.integer :pricing_mode, null: false, default: 0
      t.boolean :active,       null: false, default: true
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :products, :sku,          unique: true, where: "sku IS NOT NULL"
    add_index :products, :barcode,      unique: true, where: "barcode IS NOT NULL"
    add_index :products, :discarded_at
    add_index :products, [:active, :category_id]
    add_index :products, :name, using: :gin, opclass: :gin_trgm_ops, name: "index_products_on_name_trgm"
  end
end
