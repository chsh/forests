# encoding: UTF-8
require "spec_helper"

describe OneTableHeaders do

  before(:each) do
    OneTable.delete_all
    OneTableHeader.delete_all
  end
  it "can hold one_table_headers" do
    params = [OneTableHeader.new(:sysname => 'a', :label => 'あ'),
              OneTableHeader.new(:sysname => 'b', :label => 'い'),
              OneTableHeader.new(:sysname => 'c', :label => 'う')]
    ot = OneTable.create :one_table_headers => params, :user_id => 1, :name => 'oth1'
    oths = OneTableHeaders.new ot, params
    oths.one_table_headers.should == params
  end
  it 'can map name to instance' do
    params = [OneTableHeader.new(:sysname => 'a', :label => 'あ'),
              OneTableHeader.new(:sysname => 'b', :label => 'い', :multiple => true),
              OneTableHeader.new(:sysname => 'c', :label => 'う')]
    ot = OneTable.create :one_table_headers => params, :user_id => 1, :name => 'oth2'
    oths = OneTableHeaders.new ot, params
    oths.sysname_to_one_table_header_map.should == {
            'a' => params[0],
            'b' => params[1],
            'c' => params[2]
            }
    oths.hash_row(%w(い ろ は)).should == { 'a' => 'い', 'b' => ['ろ'], 'c' => 'は'}
    oths.hash_row(%w(い ろ), %w(う い)).should == { 'b' => ['ろ'], 'c' => 'い'}
  end
end
