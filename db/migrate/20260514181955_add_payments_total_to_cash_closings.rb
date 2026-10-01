class AddPaymentsTotalToCashClosings < ActiveRecord::Migration[8.1]
  def change
    add_column :cash_closings, :payments_total, :decimal, precision: 18, scale: 2, null: false, default: 0
  end
end
