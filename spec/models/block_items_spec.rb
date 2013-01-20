require 'spec_helper'

describe BlockItems do
  before(:each) do
  end

  it 'should choose one_table_headers from block_one_table_headers' do
    class Header
      attr_reader :id
      attr_accessor :display_index
      def initialize(id, display_index = nil)
        @id = id
        @display_index = display_index
      end
      attr_accessor :input_type
    end
    class BlockHeader
      attr_reader :one_table_header_id, :sort_index, :options
      def initialize(sort_index, one_table_header_id, options = {})
        @sort_index = sort_index
        @one_table_header_id = one_table_header_id
        @options = options
      end
    end
    headers = (1..5).map { |i| Header.new i }
    block_headers = [
            BlockHeader.new(3, 2, {:input_type => 'alpha'}),
            BlockHeader.new(1, 4),
            BlockHeader.new(2, 1, {:input_type => 'beta'}),
    ]
    bi = BlockItems.new(block_headers, headers)
    bi.sorted_headers.map(&:id).should == [4, 1, 2]
    bi.headers_with_index.map(&:display_index).should == [
        1, 2, 3, nil, nil
    ]
    bi.headers_with_index[1].input_type.should == 'beta'
    bi.headers_with_index[3].input_type.should be_nil

    headers2 = [1,2,3,4,5,nil].map { |id| Header.new(id) }
    block_headers2 = [
            BlockHeader.new(1, 3),
            BlockHeader.new(2, nil),
            BlockHeader.new(3, 2),
    ]
    bi2 = BlockItems.new(block_headers2, headers2)
    bi2.headers_with_index.map(&:display_index).should == [
        1, 2, 3, nil, nil, nil
    ]

  end
end
