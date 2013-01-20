require "spec_helper"

describe 'KVStore' do

  it "should get/put value" do
    KVStore.class_config['source'] = :memory_store
    KVStore.send :source, true
    KVStore.new('test002') do |kvs|
      kvs['a'] = 'alpha'
    end
    kvs = KVStore.new('test002')
    kvs['a'].should == 'alpha'
    MemoryStore.send :clear_contexts
    kvs2 = KVStore.new('test002')
    kvs2['a'].should be_nil
  end
end
