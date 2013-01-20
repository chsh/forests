class CreateOneTableHeaders < ActiveRecord::Migration
  def self.up
    create_table :one_table_headers do |t|
      t.integer :one_table_id, :null => false
      t.string :label, :sysname, :refname
      t.integer :kind, :index
      t.boolean :multiple, :default => false
      t.timestamps
    end
    add_index :one_table_headers, [:one_table_id, :index]
  end

  def self.down
    drop_table :one_table_headers
  end
end
