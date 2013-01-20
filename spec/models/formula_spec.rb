require 'spec_helper'

describe Formula do
  before(:each) do
  end

  it 'should return new_instance.' do
    fcj = Formula::ConvertJoin.create :one_table_header_id => 1, :params => {:delimiter => 'aaa', :fields => ['h1', 'h3']}
    new_fcj = fcj.new_instance
    new_fcj.class.should == Formula::ConvertJoin
    new_fcj.params.should == {:delimiter => 'aaa', :fields => ['h1', 'h3']}
  end
end
