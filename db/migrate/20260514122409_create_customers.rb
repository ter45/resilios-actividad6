class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers do |t|
      t.integer :document_type,   null: false, default: 0
      t.string  :document_number
      t.string  :name,            null: false
      t.string  :phone
      t.string  :address

      t.decimal :credit_limit,    precision: 18, scale: 2, null: false, default: 0
      t.decimal :credit_balance,  precision: 18, scale: 2, null: false, default: 0

      t.boolean :active,          null: false, default: true
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :customers, :document_number, unique: true, where: "document_number IS NOT NULL"
    add_index :customers, :discarded_at
    add_index :customers, :name, using: :gin, opclass: :gin_trgm_ops, name: "index_customers_on_name_trgm"
    add_index :customers, :phone, where: "phone IS NOT NULL"
  end
end
