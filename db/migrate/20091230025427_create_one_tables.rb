class CreateOneTables < ActiveRecord::Migration
  def self.up
    create_table :one_tables do |t|
      t.integer :user_id, :null => false
      t.string :name, :null => false
      t.integer :mongo_connection_id, :solr_connection_id, :null => false
      t.string :status
      t.integer :media_keeper_id
      t.timestamps
    end
    add_index :one_tables, [:user_id, :name], :unique => true
  end

  def self.down
    drop_table :one_tables
  end
end
