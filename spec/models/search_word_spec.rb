require 'spec_helper'

describe SearchWord do
  before(:each) do
    @valid_attributes = {
      :search_word_list_id => 1,
      :index => 1,
      :display_value => "value for display_value",
      :search_value => "value for search_value"
    }
  end

  it "should create a new instance given valid attributes" do
    SearchWord.create!(@valid_attributes)
  end
end
