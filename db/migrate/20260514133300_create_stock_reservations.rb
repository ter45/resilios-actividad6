class CreateStockReservations < ActiveRecord::Migration[8.1]
  def change
    create_table :stock_reservations do |t|
      t.references :product,    null: false, foreign_key: true
      t.references :user,       null: false, foreign_key: true
      t.string  :cart_id,       null: false
      t.string  :terminal_id,   null: false
      t.decimal :quantity,      precision: 18, scale: 3, null: false
      t.datetime :expires_at,   null: false

      t.timestamps
    end

    add_index :stock_reservations, :cart_id
    add_index :stock_reservations, :expires_at
    add_index :stock_reservations, [:product_id, :expires_at]
  end
end
