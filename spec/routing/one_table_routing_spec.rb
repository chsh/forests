require 'spec_helper'

describe OneTablesController do
  describe "routing" do
    it "recognizes and generates #duplicate" do
      { :post => "/one_tables/1/duplicate" }.should route_to(:controller => "one_tables", :action => "duplicate", :id => '1')
    end
  end
end
