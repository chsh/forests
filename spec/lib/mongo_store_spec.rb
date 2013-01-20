# encoding: UTF-8
require "spec_helper"

describe 'MongoStore' do

  before(:each) do
    cc = MongoStore.class_config
    host = cc['host'] || 'localhost'
    port = (cc['port'] || 27017).to_i
    dbname = cc['database']
    con = Mongo::Connection.new host, port
    con.drop_database dbname
  end

  it "should get/put value" do
    MongoStore.new('test001') do |db|
      db['いろは'] = '英数字'
      db['abc'] = 15000
    end
    ms = MongoStore.new('test001')
    ms['いろは'].should == '英数字'
  end

  it 'should remove value.' do
    MongoStore.new('test002') do |db|
      db['いろは'] = '英数字'
      db['abc'] = 15000
    end
    ms = MongoStore.new('test002')
    ms.delete 'いろは'
    ms['いろは'].should be_nil

  end

end
