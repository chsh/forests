class CreateBlockOneTableHeaders < ActiveRecord::Migration
  def self.up
    create_table :block_one_table_headers do |t|
      t.integer :block_id, :one_table_header_id, :null => false
      t.integer :sort_index, :null => false
      t.text :options
      t.timestamps
    end
    add_index :block_one_table_headers, [:block_id, :sort_index]
    add_index :block_one_table_headers, :one_table_header_id
  end

  def self.down
    drop_table :block_one_table_headers
  end
end
