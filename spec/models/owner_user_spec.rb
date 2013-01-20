require 'spec_helper'

describe OwnerUser do
  before(:each) do
  end

  it 'can create instance with owner_id and user_id' do
    lambda {
      OwnerUser.create!
    }.should raise_error
    lambda {
      OwnerUser.create! :owner_id => 1
    }.should raise_error
    lambda {
      OwnerUser.create! :user_id => 2
    }.should raise_error
    lambda {
      OwnerUser.create! :owner_id => 1, :user_id => 2
    }.should_not raise_error
    # same owner and user is not allowed.
    lambda {
      OwnerUser.create! :owner_id => 1, :user_id => 1
    }.should raise_error
  end

  it 'can create instance by user login or email.' do
    create :user, :email => 'test1@example.com'
    create :user, :email => 'test2@example.com'
    lambda {
      OwnerUser.create! :owner_id => 100, :user_email => 'hogehoge@hoge.com'
    }.should raise_error
    lambda {
      OwnerUser.create! :owner_id => 102, :user_email => 'test2@example.com'
    }.should_not raise_error
  end
end
