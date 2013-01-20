require 'spec_helper'

require 'mongo'

describe MongoConnection do
  before do
    @user = create :user
    MongoConnection.default.destroy if MongoConnection.default
    MongoConnection.default_gridfs.destroy if MongoConnection.default_gridfs
    @cc_default_gridfs = MongoConnection.class_config['default_gridfs']
    @cc_default = MongoConnection.class_config['default']
  end

  it 'can be destroyed' do
    mc = Mongo::Connection.new(@cc_default['host'], @cc_default['port'].to_i)
    # mc.database_names.include?('forests-test').should == false
    instance = MongoConnection.create :host => @cc_default['host'], :port => @cc_default['port'].to_i,
            :db => 'forests-test', :name => 'test1'
    col = instance.remote_connection.collection('test1')
    status = col.save :a => 100
    status.should_not be_nil
    mc.database_names.include?('forests-test').should == true
    instance.destroy
    mc.database_names.include?('forests-test').should == false
  end

  after do
    MongoConnection.default.destroy
    MongoConnection.default_gridfs.destroy
  end
end
