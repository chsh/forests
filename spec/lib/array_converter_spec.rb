# encoding: UTF-8
require "spec_helper"

describe ArrayConverter do

  it "should should create partial list" do
    ArrayConverter.partial_list([1,2,3]).sort.should == ["1", "12", "123", "13", "2", "23", "3"]
    ArrayConverter.partial_list(['a','b','c'], :delimiter => ':').sort.should == ["a", "a:b", "a:b:c", "a:c", "b", "b:c", "c"]
    ArrayConverter.partial_list(:sym, :bol).sort.should == ["bol", "bolsym", "sym"]
    ArrayConverter.partial_list('一つ').sort.should == ["一つ"]
    ArrayConverter.partial_list(1,2,3,4).sort.should == ["1", "12", "123", "1234", "124", "13", "134", "14",
                                                         "2", "23", "234", "24",
                                                         "3", "34",
                                                         "4"]
  end
end
