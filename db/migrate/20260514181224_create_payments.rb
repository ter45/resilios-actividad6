class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :credit,     null: false, foreign_key: true
      t.references :customer,   null: false, foreign_key: true
      t.references :user,       null: false, foreign_key: true

      t.string  :terminal_id,   null: false
      t.decimal :amount,        precision: 18, scale: 2, null: false
      t.datetime :paid_at,      null: false
      t.text :notes

      t.timestamps
    end

    add_index :payments, :paid_at
    add_index :payments, [:terminal_id, :paid_at]
    add_index :payments, [:user_id, :paid_at]
  end
end
