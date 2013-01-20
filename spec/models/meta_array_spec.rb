# encoding: UTF-8
require "spec_helper"

describe MetaArray do
  it "should should hold metadata inside" do
    ma = MetaArray.from(["あいうえお", :symname, 12.443], :news => true, :title => 'ABC')
    ma.should == ["あいうえお", :symname, 12.443]
    ma.metadata[:news].should be_true
    ma.metadata[:title].should == 'ABC'
  end
end
