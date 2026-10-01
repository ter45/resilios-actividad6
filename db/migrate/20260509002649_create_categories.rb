class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string  :name,         null: false
      t.string  :code
      t.integer :position,     null: false, default: 0
      t.boolean :active,       null: false, default: true
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :categories, :name, unique: true
    add_index :categories, :code, unique: true, where: "code IS NOT NULL"
    add_index :categories, :discarded_at
    add_index :categories, [:active, :position]
  end
end
