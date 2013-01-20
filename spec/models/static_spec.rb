require 'spec_helper'

describe Static do
  it 'can read class_config setting as method.' do
    Static.jquery.should == 'http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js'
    Static.jquery_ui.should == "http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.2/jquery-ui.min.js"
    lambda {
      Static.not_existent
    }.should raise_error
  end
end
