class CreateSolrConnections < ActiveRecord::Migration
  def self.up
    create_table :solr_connections do |t|
      t.string :name, :null => false, :unique => true
      t.string :url, :null => false
      t.text :options
      t.string :sha, :limit => 40, :null => false, :unique => true
      t.timestamps
    end
  end

  def self.down
    drop_table :solr_connections
  end
end
