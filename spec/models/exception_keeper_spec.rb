require 'spec_helper'

describe ExceptionKeeper do
  before(:each) do
  end

  it "should create a new instance given valid attributes" do
    lambda {
      ExceptionKeeper.create!
    }.should raise_error
    lambda {
      ExceptionKeeper.create! :keepable_type => 'OneTable'
    }.should raise_error
    lambda {
      ExceptionKeeper.create! :keepable_id => 1
    }.should raise_error
    lambda {
      ExceptionKeeper.create! :keepable_type => 'OneTable', :keepable_id => 1
    }.should raise_error
    lambda {
      ExceptionKeeper.create! :keepable_type => 'OneTable', :keepable_id => 1,
                              :class_name => 'RuntimeException'
    }.should raise_error
    lambda {
      ExceptionKeeper.create! :keepable_type => 'OneTable', :keepable_id => 1,
                              :class_name => 'RuntimeException',
                              :message => 'Test message'
    }.should raise_error
    lambda {
      ExceptionKeeper.create! :keepable_type => 'OneTable', :keepable_id => 1,
                              :class_name => 'RuntimeException',
                              :message => 'Test message',
                              :backtrace => 'hello'
    }.should raise_error
    ek = ExceptionKeeper.create! :keepable_type => 'OneTable', :keepable_id => 1,
                            :class_name => 'RuntimeException',
                            :message => 'Test message',
                            :backtrace => ['hello', 'world', 'everyone']

    [:keepable_type, :keepable_id,
     :class_name, :message, :backtrace].map { |msg| ek.send msg }.should == [
            'OneTable', 1,
            'RuntimeException', 'Test message', ['hello', 'world', 'everyone']
    ]
  end

  it 'should have exception=(e) method.' do
    ek_org = ExceptionKeeper.new :keepable_type => 'Block', :keepable_id => 2
    class ExceptionForTest < StandardError
      def backtrace; ['hello', 'world', 'everyone']; end
      def message; 'Test message'; end
    end
    ek_org.exception = ExceptionForTest.new
    ek_org.save!
    ek = ExceptionKeeper.find ek_org.id

    [:keepable_type, :keepable_id,
     :class_name, :message, :backtrace].map { |msg| ek.send msg }.should == [
            'Block', 2,
            'ExceptionForTest', 'Test message', ['hello', 'world', 'everyone']
    ]
  end
end
