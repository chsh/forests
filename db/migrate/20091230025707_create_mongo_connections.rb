class CreateMongoConnections < ActiveRecord::Migration
  def self.up
    create_table :mongo_connections do |t|
      t.string :name, :null => false, :unique => true
      t.string :host, :port, :db, :null => false
      t.string :sha, :limit => 40, :null => false, :unique => true
      t.timestamps
    end
  end

  def self.down
    drop_table :mongo_connections
  end
end
