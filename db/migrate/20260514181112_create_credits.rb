class CreateCredits < ActiveRecord::Migration[8.1]
  def change
    create_table :credits do |t|
      t.references :customer,    null: false, foreign_key: true
      t.references :sale,        null: false, foreign_key: true

      t.decimal :amount,         precision: 18, scale: 2, null: false
      t.decimal :balance,        precision: 18, scale: 2, null: false

      t.integer :status,         null: false, default: 0
      t.datetime :paid_at

      t.timestamps
    end

    add_index :credits, :status
    add_index :credits, [:customer_id, :status]
    add_index :credits, :paid_at
  end
end
