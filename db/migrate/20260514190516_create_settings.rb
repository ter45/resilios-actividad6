class CreateSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :settings do |t|
      t.string :business_name,    null: false, default: "Minimercado"
      t.string :legal_name
      t.string :nit
      t.string :address
      t.string :phone
      t.string :city,             default: "Bogotá"

      t.string :ticket_header
      t.string :ticket_footer

      t.boolean :print_barcode,   null: false, default: false
      t.integer :paper_width_mm,  null: false, default: 80

      t.timestamps
    end
  end
end
