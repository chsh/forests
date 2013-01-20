require "spec_helper"

describe Digester do

  it 'should create digest from strings.' do
    dig1 = Digester.new 'alpha', 'beta'
    dig1.hexdigest.should == '0c645492c58ad3fe8338329bbd9ad42a0ae78456'
    dig1a = Digester.new 'alpha', 'beta', :digester => :sha1
    dig1a.hexdigest.should == '0c645492c58ad3fe8338329bbd9ad42a0ae78456'
    dig2 = Digester.new 'alpha', 'beta', :digester => :md5
    dig2.hexdigest.should == '66bebefb99d3d4ddae3331821c07dccc'

    lambda {
      Digester.new 'alpha', 'beta', 'gamma', :digester => :not_existent_type
    }.should raise_error
  end
end
