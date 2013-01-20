class BlockItems
  def initialize(block_headers, all_headers)
    @block_headers = block_headers
    @all_headers = all_headers
  end
  def sorted_headers
    @sorted_headers ||= build_sorted_headers
  end
  def headers_with_index
    @headers_with_index ||= build_headers_with_index
  end

  def update_by(editable_items_attrs)
    block.block_one_table_headers.clear
    editable_items_attrs.each do |oth_id, attrs|
      oth = nil
      if oth_id.to_s == OneTableHeaderValue::FREEWORD_SEARCH.id.to_s
        oth = OneTableHeaderValue::FREEWORD_SEARCH
      else
        oth = block.one_table.one_table_headers.find(oth_id)
      end
      create_one_table_headers_from oth, attrs
    end
  end
  protected
  attr_accessor :block
  def attrs_options(attrs); {}; end
  private
  def create_one_table_headers_from(oth, attrs)
    di = attrs['display_index']
    return if di.blank?
    block.block_one_table_headers.create :one_table_header_id => oth.id,
                                          :sort_index => di.to_i,
                                          :options => attrs_options(attrs)
  end
  def setup_header(header, block_header)
    header.display_index = block_header.sort_index
    block_header.options.each do |key, value|
      header.send("#{key}=", value) if header.respond_to? key
    end
  end
  def build_headers_with_index
    @all_headers.map do |h|
      setup_header h, one_table_header_id_map_block_headers[h.id]
      h
    end.sort { |a, b|
      di_a = a.display_index || 99999999999
      di_b = b.display_index || 99999999999
      di_a <=> di_b
    }
  end
  def one_table_header_id_map_block_headers
    @one_table_header_id_map_block_headers ||= build_one_table_header_id_map_block_headers
  end
  def idmap_all_headers
    @idmap_all_headers ||= build_idmap_all_headers
  end
  def build_idmap_all_headers
    @all_headers.refmap(&:id)
  end
  def build_sorted_headers
    sorted_block_headers.map { |bh| idmap_all_headers[bh.one_table_header_id] }
  end
  def sorted_block_headers
    @sorted_block_headers ||= build_sorted_block_headers
  end
  def build_sorted_block_headers
    @block_headers.sort do |bh_a, bh_b|
      bh_a.sort_index <=> bh_b.sort_index
    end
  end
  class NullBlockHeader
    def sort_index; nil; end
    def options; {}; end
  end
  def build_one_table_header_id_map_block_headers
    @block_headers.refmap(NullBlockHeader.new, &:one_table_header_id)
  end
end
