class ListDisplayItems < ActiveRecord::Base
  SELECTIONS = [
          ['display'], ['link']
  ]
  def initialize(block)
    @block = block
    @one_table = block.one_table
  end

  def items
    @one_table_headers ||= build_items
  end

  private
  def build_items
    BlockItems.new(@block.block_one_table_headers, @one_table.one_table_headers).headers_with_index
  end
end
