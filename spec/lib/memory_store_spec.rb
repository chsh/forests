# encoding: UTF-8
require "spec_helper"

describe 'MemoryStore' do

  before(:each) do
    MemoryStore.send :clear_contexts
  end

  it "should get/put value" do
    ms0 = MemoryStore.new('test001')
    ms0['いろは'].should be_nil
    ms0['いろは'] = '日本語'
    ms0['いろは'].should == '日本語'
    MemoryStore.new('test001') do |db|
      db['いろは'] = '英数字'
      db['abc'] = 15000
    end
    MemoryStore.send :clear_contexts
    ms = MemoryStore.new('test001')
    ms['いろは'].should be_nil
    MemoryStore.new('test001') do |db|
      db['いろは'] = '英数字'
      db['abc'] = 15000
    end
    ms2 = MemoryStore.new('test001')
    ms2['いろは'].should == '英数字'

    ms3 = MemoryStore.new('test002')
    ms3['あいう'] = 'abc'
    ms3['あいう'].should == 'abc'
    ms3.delete 'あいう'
    ms3['あいう'].should be_nil

  end
end
