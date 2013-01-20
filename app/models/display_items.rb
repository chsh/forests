class DisplayItems < ActiveRecord::Base
  def initialize(block)
    @block = block
    @one_table = block.one_table
  end

  def items
    @one_table_headers ||= build_items
  end

  private
  def build_items
    @one_table.one_table_headers.map do |oth|
      si = @block.search_items.find_by_one_table_header_id oth.id
      if si
        oth.display_order = si.display_order
      end
      oth
    end
  end
end
