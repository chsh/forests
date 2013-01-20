
require 'mongo'

class MongoConnection < ActiveRecord::Base
#  has_many :one_tables
#  has_many :mongo_attachments
  def remote_connection
    mongo_connection.db(db)
  end
  before_create :fill_empty_values
  def fill_empty_values
    unless self[:sha]
      attrs = self.attributes.except 'id', 'sha', 'created_at', 'updated_at'
      self[:sha] = digest_hash attrs
    end
  end
  before_destroy :drop_mongo_database
  def drop_mongo_database
    mongo_connection.drop_database db
  end
  def verify_connection
    self.remote_connection
  end
  def self.default
    @@default_connection ||= new(class_config['default'])
  end
  def self.default_gridfs
    @@default_gridfs_connection ||= new(class_config['default_gridfs'])
  end
  def self.site_filesystem
    @@site_filesystem_connection ||= new(class_config['site_filesystem'])
  end
  def self.media_keeper
    @@site_media_keeper_connection ||= new(class_config['media_keeper'])
  end
  private
  def mongo_connection
    Mongo::Connection.new(host, port.to_i, :pool_size => 10, :pool_timeout => 5)
  end
  def digest_hash(hash)
    Digest::SHA1.hexdigest hash.to_param
  end
end
