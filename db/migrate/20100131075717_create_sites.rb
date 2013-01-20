class CreateSites < ActiveRecord::Migration
  def self.up
    create_table :sites do |t|
      t.integer :user_id, :null => false
      t.string :name
      t.text :site_attributes
      t.string :virtualhost
      t.boolean :clonable, :default => false
      t.timestamps
    end
    add_index :sites, :user_id
    add_index :sites, :name, :unique => true
    add_index :sites, :virtualhost, :unique => true
  end

  def self.down
    drop_table :sites
  end
end
