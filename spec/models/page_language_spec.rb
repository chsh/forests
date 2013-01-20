# encoding: UTF-8
require 'spec_helper'

describe PageLanguage do

  it "should have pages' selectable langs." do
    PageLanguage.select_options.should == [['HTML', 'text'], ['PDF', 'pdf'], ['ruby', 'ruby']]
  end

end
