# encoding: UTF-8
require "spec_helper"

describe SiteAttributes do

  before(:each) do
    @user = create :user
    @site = @user.sites.create! :name => 'newsite_site_attributes'
  end

  it "should should load/save attributes" do
    sa = SiteAttributes.new @site
    sa[:a] = 'abcアルファ'
    @site.attrs['a'].should == 'abcアルファ'
    sa['b'] = '値'
    @site.attrs[:b].should == '値'
  end

  after(:each) do
    @user.destroy
  end
end
