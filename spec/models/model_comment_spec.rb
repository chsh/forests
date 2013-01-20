require 'spec_helper'

describe ModelComment do
  before(:each) do
    @valid_attributes = {
      :commentable_type => 'ModelComment',
      :commentable_id => 100
    }
  end

  it "should create a new instance given valid attributes" do
    ModelComment.create!(@valid_attributes)
  end
end
