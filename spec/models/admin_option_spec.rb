require 'spec_helper'

describe AdminOption do
  before(:each) do
  end

  it 'should save any attributes.' do
    ao = AdminOption.new
    ao.site = 100
    ao.attrs[:site].should == 100
    ao[:conf] = 'alpha-beta'
    ao.save

    lambda {
      ao.foo_baa
    }.should raise_error

    ao2 = AdminOption.find ao.id
    ao2.site.should == 100
    ao2.attrs.should == { 'conf' => 'alpha-beta', 'site' => 100 }
  end
end
