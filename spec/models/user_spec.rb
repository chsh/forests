# -*- coding: utf-8 -*-

require 'spec_helper'

describe User do
  before(:each) do
  end

=begin
  it 'should have level attribute' do
  s  u1 = create :user
    u1.level.should == User::LEVEL_ADMIN
    u2 = create :inactive_user
    u2.level.should == User::LEVEL_INACTIVE
    u3 = create :site_user
    u3.level.should == User::LEVEL_VIEWABLE
    u4 = create :site_admin_user
    u4.level.should == User::LEVEL_EDITABLE
  end
=end
=begin
  it "should create a new instance given valid attributes" do
    User.create.id.should be_nil
    User.create({:login => 'hoho-example.com',
                 :password => 'pass2010'}).id.should_not be_nil
    User.create({:login => 'test-example.com', :password => 'pass2010',
                 :password_confirmation => 'pass2010'}).id.should_not be_nil
  end
=end
  it 'should destroy when instance destroyed.' do
    ud = create :site_user
    site = ud.sites.create :name => 'ud_site1'
    ud.sites.size.should == 1
    ud.destroy
    lambda {
      Site.find site.id
    }.should raise_error
  end

=begin
  it 'should return level as string.' do
    ulev = create :site_admin_user
    ulev.level_as_string.should == "データ閲覧・編集可能"
  end
=end
  after(:each) do
    User.delete_all
  end
end
