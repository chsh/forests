class CreateSiteFiles < ActiveRecord::Migration
  def self.up
    create_table :site_files do |t|
      t.integer :site_id, :null => false
      t.string :path, :null => false
      t.string :parent_id
      t.boolean :folder, :default => false
      t.timestamps
    end
    add_index :site_files, :parent_id
    add_index :site_files, [:site_id, :path], :unique => true
  end

  def self.down
    drop_table :site_files
  end
end
