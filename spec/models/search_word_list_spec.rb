# encoding: UTF-8
require 'spec_helper'

describe SearchWordList do
  before(:each) do
    @valid_attributes = {
      :user_id => 1,
      :name => "value for name"
    }
  end

  it "should create a new instance given valid attributes" do
    SearchWordList.create!(@valid_attributes)
  end

  it 'should have search word listing for select.' do
    swl = SearchWordList.create :name => 'swl-abc'
    swl.search_words.create :index => 1, :display_value => 'ho', :search_value => 'yo'
    swl.search_words.create :index => 3, :display_value => 'mo', :search_value => 'to'
    swl.search_words.create :index => 2, :display_value => '表示', :search_value => '検索'
    swl.search_words_for_select_or_checkbox.should == [
            ['ho', 'yo'],
            ['表示', '検索'],
            ['mo', 'to']
    ]
  end

end
