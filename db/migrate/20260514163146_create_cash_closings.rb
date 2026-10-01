class CreateCashClosings < ActiveRecord::Migration[8.1]
  def change
    create_table :cash_closings do |t|
      t.references :user,        null: false, foreign_key: true
      t.string  :terminal_id,    null: false

      t.datetime :opened_at,     null: false
      t.datetime :closed_at,     null: false

      t.decimal :expected_cash,  precision: 18, scale: 2, null: false, default: 0
      t.decimal :counted_cash,   precision: 18, scale: 2, null: false, default: 0
      t.decimal :difference,     precision: 18, scale: 2, null: false, default: 0

      t.decimal :credit_total,   precision: 18, scale: 2, null: false, default: 0
      t.integer :sales_count,    null: false, default: 0
      t.integer :voided_count,   null: false, default: 0

      t.text :notes

      t.timestamps
    end

    add_index :cash_closings, :terminal_id
    add_index :cash_closings, :closed_at
    add_index :cash_closings, [:terminal_id, :closed_at]
  end
end
