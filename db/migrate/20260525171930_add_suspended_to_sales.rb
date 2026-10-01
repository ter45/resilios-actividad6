class AddSuspendedToSales < ActiveRecord::Migration[8.1]
  def change
    add_column :sales, :suspended_at,    :datetime
    add_column :sales, :suspended_notes, :text

    add_index :sales, [:terminal_id, :suspended_at]
    add_index :sales, :suspended_at
  end
end
