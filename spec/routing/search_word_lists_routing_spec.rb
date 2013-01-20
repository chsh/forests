require 'spec_helper'

describe SearchWordListsController do
  describe "routing" do
    it "recognizes and generates #index" do
      { :get => "/search_word_lists" }.should route_to(:controller => "search_word_lists", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/search_word_lists/new" }.should route_to(:controller => "search_word_lists", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/search_word_lists/1" }.should route_to(:controller => "search_word_lists", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/search_word_lists/1/edit" }.should route_to(:controller => "search_word_lists", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/search_word_lists" }.should route_to(:controller => "search_word_lists", :action => "create") 
    end

    it "recognizes and generates #update" do
      { :put => "/search_word_lists/1" }.should route_to(:controller => "search_word_lists", :action => "update", :id => "1") 
    end

    it "recognizes and generates #destroy" do
      { :delete => "/search_word_lists/1" }.should route_to(:controller => "search_word_lists", :action => "destroy", :id => "1") 
    end
  end
end
