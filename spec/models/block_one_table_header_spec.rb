require 'spec_helper'

describe BlockOneTableHeader do
  before(:each) do
    @valid_attributes = {
            :block_id => 1, :one_table_header_id => 100,
            :sort_index => 2
    }
  end

  it "should create a new instance given valid attributes" do
    BlockOneTableHeader.create!(@valid_attributes)
  end
end
