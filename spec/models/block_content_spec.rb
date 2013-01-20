require 'spec_helper'

describe BlockContent do
  before(:each) do
    @user = create :user
    @site = @user.sites.create :name => 'site1'
    @block = @site.blocks.create :name => 't1'
  end
  after(:each) do
    @block.destroy
  end

  it "should create a new instance given valid attributes" do
    @block.block_contents.create!
  end
end
