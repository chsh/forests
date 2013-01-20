# encoding: UTF-8
require 'spec_helper'

describe MetaString do
  it 'should hold metada inside.' do
    ms = MetaString.from "あいうえお", :news => true, :title => 'ABC'
    ms.should == 'あいうえお'
    ms.metadata[:news].should be_true
    ms.metadata[:title].should == 'ABC'
  end
end
