require 'spec_helper'

describe SiteAttributesController do
  describe "routing" do
    it "recognizes and generates #index" do
      { :get => "/sites/1/site_attributes" }.should route_to(:controller => "site_attributes", :action => "index", :site_id => '1')
    end

    it "recognizes and generates #new" do
      { :get => "/sites/1/site_attributes/new" }.should route_to(:controller => "site_attributes", :action => "new", :site_id => '1')
    end

    it "recognizes and generates #show" do
      { :get => "/sites/1/site_attributes/1" }.should route_to(:controller => "site_attributes", :action => "show", :id => "1", :site_id => '1')
    end

    it "recognizes and generates #edit" do
      { :get => "/sites/1/site_attributes/1/edit" }.should route_to(:controller => "site_attributes", :action => "edit", :id => "1", :site_id => '1')
    end

    it "recognizes and generates #create" do
      { :post => "/sites/1/site_attributes" }.should route_to(:controller => "site_attributes", :action => "create", :site_id => '1')
    end

    it "recognizes and generates #update" do
      { :put => "/sites/1/site_attributes/1" }.should route_to(:controller => "site_attributes", :action => "update", :id => "1", :site_id => '1')
    end

    it "recognizes and generates #destroy" do
      { :delete => "/sites/1/site_attributes/1" }.should route_to(:controller => "site_attributes", :action => "destroy", :id => "1", :site_id => '1')
    end
  end
end
