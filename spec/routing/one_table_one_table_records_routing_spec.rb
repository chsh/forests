require 'spec_helper'

describe OneTableRecordsController do
  describe "routing" do
    it "recognizes and generates #index" do
      { :get => "/one_tables/123/one_table_records/abcdef12345" }.should route_to(controller: "one_table_records", action: "show", one_table_id: '123', id: 'abcdef12345')
    end
  end
end
