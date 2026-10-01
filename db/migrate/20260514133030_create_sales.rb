class CreateSales < ActiveRecord::Migration[8.1]
  def change
    create_table :sales do |t|
      t.string  :number,            null: false
      t.string  :terminal_id,       null: false
      t.references :user,           null: false, foreign_key: true
      t.references :customer,       null: true,  foreign_key: true

      t.decimal :subtotal,          precision: 18, scale: 2, null: false, default: 0
      t.decimal :tax_total,         precision: 18, scale: 2, null: false, default: 0
      t.decimal :discount_total,    precision: 18, scale: 2, null: false, default: 0
      t.decimal :total,             precision: 18, scale: 2, null: false, default: 0

      t.decimal :cash_amount,       precision: 18, scale: 2, null: false, default: 0
      t.decimal :credit_amount,     precision: 18, scale: 2, null: false, default: 0

      t.integer :payment_method,    null: false, default: 0
      t.integer :status,            null: false, default: 0

      t.datetime :sold_at
      t.datetime :voided_at
      t.text :voided_reason
      t.references :voided_by,      null: true, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :sales, :number,             unique: true
    add_index :sales, :terminal_id
    add_index :sales, :sold_at
    add_index :sales, :status
    add_index :sales, [:terminal_id, :sold_at]
    add_index :sales, [:status, :sold_at]
  end
end
