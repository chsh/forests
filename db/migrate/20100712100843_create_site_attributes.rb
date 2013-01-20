class CreateSiteAttributes < ActiveRecord::Migration
  def self.up
    create_table :site_attributes do |t|
      t.integer :site_id, :null => false
      t.string :key, :value
      t.text :metadata
      t.timestamps
    end
    add_index :site_attributes, [:site_id, :key], :unique => true
  end

  def self.down
    drop_table :site_attributes
  end
end
