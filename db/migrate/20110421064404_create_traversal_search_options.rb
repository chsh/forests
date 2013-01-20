class CreateTraversalSearchOptions < ActiveRecord::Migration
  def self.up
    create_table :traversal_search_options do |t|
      t.integer :one_table_id, null: false
      t.text :options
      t.timestamps
    end
    add_index :traversal_search_options, :one_table_id
  end

  def self.down
    drop_table :traversal_search_options
  end
end
