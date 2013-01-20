class SolrConnection < ActiveRecord::Base
  has_many :one_tables
  serialize :options, Hash

=begin
  class SolrClientProxy
    def initialize(rsolr_client)
      @rsolr_client = rsolr_client
    end
    def update(data)
      @rsolr_client.update :data => data
    end
    def commit(*args)
      @rsolr_client.commit *args
    end
    def rollback(*args)
      @rsolr_client.rollback *args
    end
    def delete_by_query(*args)
      @rsolr_client.delete_by_query *args
    end
  end
=end
  def remote_connection
    @remote_connection ||= build_remote_connection
  end
  before_create :fill_empty_values
  def fill_empty_values
    unless self[:sha]
      attrs = self.attributes.except 'id', 'sha', 'created_at', 'updated_at'
      self[:sha] = digest_hash attrs
    end
  end
  before_destroy :delete_all_solr_docs
  def delete_all_solr_docs
    self.remote_connection.delete_by_query '*:*'
    self.remote_connection.commit
  end
  def options
    self[:options] ||= {}
  end
  def verify_connection
    self.remote_connection.query '*:*'
  end
  def self.default
    @@default_connection ||= new(class_config['default'])
  end
  private
  def digest_hash(hash)
    Digest::SHA1.hexdigest hash.to_param
  end

  def build_remote_connection
    RSolr.connect options.merge(url: url)
#    SolrClientProxy.new rc
  end
end
