require 'spec_helper'

describe SiteFile do
  before(:each) do
    @user = create :user
  end
  after(:each) do
    @user.destroy
  end

  it "should create a new instance given valid attributes" do
    lambda {
      SiteFile.create!
    }.should raise_error

    lambda {
      SiteFile.create! :site_id => 1
    }.should raise_error

    site = @user.sites.create! :name => 'test3'
    sf = SiteFile.create! :site_id => site.id, :path => 'test/image.gif', :file => 'spec/files/site_files/bt-search.gif'
    sf.folder.should == false
    site.files.content('test/image.gif').should == File.open('spec/files/site_files/bt-search.gif', 'rb').read
    sf.update_attributes file: 'spec/files/site_files/bt-search-2.gif'
    site.files.content('test/image.gif').should == File.open('spec/files/site_files/bt-search-2.gif', 'rb').read
  end

  it 'should detect content type.' do

    SiteFile.new(path: 'hello.txt').text?.should be_true
    SiteFile.new(path: 'test/image.gif').text?.should_not be_true
    SiteFile.new(path: 'stylesheets/style.css').text?.should be_true
    SiteFile.new(path: 'javascripts/app.js').text?.should be_true
    SiteFile.new(path: 'index.html').text?.should be_true
    SiteFile.new(path: 'win/index.htm').text?.should be_true
  end

  it 'should invalidate cache after save.' do
    RawMemCache["/test-invalidate-cache/test/image.gif"] = 'xyz'
    site = @user.sites.create! :name => 'test-invalidate-cache'
    sf = SiteFile.create! :site_id => site.id, :path => 'test/image.gif', :file => 'spec/files/site_files/bt-search.gif'
    RawMemCache["/test-invalidate-cache/test/image.gif"].should be_nil
  end
end
