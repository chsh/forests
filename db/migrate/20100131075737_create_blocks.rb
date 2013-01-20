class CreateBlocks < ActiveRecord::Migration
  def self.up
    create_table :blocks do |t|
      t.integer :user_id, :one_table_id, :site_id
      t.string :name
      t.integer :kind
      t.string :conditions
      t.string :order
      t.string :limit
      t.timestamps
    end
    add_index :blocks, [:user_id, :one_table_id]
    add_index :blocks, [:site_id, :name], :unique => true
  end

  def self.down
    drop_table :blocks
  end
end
