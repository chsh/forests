class AddPrimaryKeyToOneTableHeader < ActiveRecord::Migration
  def change
    add_column :one_table_headers, :primary_key, :boolean, default: false
  end
end
