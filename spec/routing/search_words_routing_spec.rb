require 'spec_helper'

describe SearchWordsController do
  describe "routing" do
    it "recognizes and generates #index" do
      { :get => "/search_word_lists/1/search_words" }.should route_to(:controller => "search_words", :action => "index", :search_word_list_id => '1')
    end

    it "recognizes and generates #new" do
      { :get => "/search_word_lists/1/search_words/new" }.should route_to(:controller => "search_words", :action => "new", :search_word_list_id => '1')
    end

    it "recognizes and generates #show" do
      { :get => "/search_word_lists/1/search_words/1" }.should route_to(:controller => "search_words", :action => "show", :id => "1", :search_word_list_id => '1')
    end

    it "recognizes and generates #edit" do
      { :get => "/search_word_lists/1/search_words/1/edit" }.should route_to(:controller => "search_words", :action => "edit", :id => "1", :search_word_list_id => '1')
    end

    it "recognizes and generates #create" do
      { :post => "/search_word_lists/1/search_words" }.should route_to(:controller => "search_words", :action => "create", :search_word_list_id => '1')
    end

    it "recognizes and generates #update" do
      { :put => "/search_word_lists/1/search_words/1" }.should route_to(:controller => "search_words", :action => "update", :id => "1", :search_word_list_id => '1')
    end

    it "recognizes and generates #destroy" do
      { :delete => "/search_word_lists/1/search_words/1" }.should route_to(:controller => "search_words", :action => "destroy", :id => "1", :search_word_list_id => '1')
    end
  end
end
