# -*- encoding: UTF-8 -*-

require 'spec_helper'

describe OneTablesHelper do

  it 'should hilite text with params.' do
    hilite_query('abc').should == 'abc'
    hilite_query('abcdef', limit: 4).should == 'abcd'
    hilite_query('いろは', limit: 2, query: 'い').should == '<span style="background-color: yellow"><em>い</em></span>ろ'
    hilite_query(nil).should be_nil
    hilite_query(['abc', 'xyz'], limit: 6).should == 'abc, x'
    hilite_query(Date.parse('2011/4/1'), query: 'abc').should == '2011-04-01'
    hilite_query(Time.parse('2011/4/2 12:45:01')).should == '2011-04-02 12:45:01 +0900'
  end

end
