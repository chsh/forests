# encoding: UTF-8
class SearchItems < BlockItems
  SELECTIONS = [
          ['テキスト', 'text'], ['セレクト', 'select'], ['チェックボックス', 'checkbox'],
          ['日付', 'date'], ['日付(曜日)', 'date:wday'], ['日付[JS]', 'date:pc'], ['日付(曜日)[JS]', 'date:wday:pc'], ['日付(曜日)[廃止予定]', 'date_wday']
  ]
  def initialize(block)
    super(block.block_one_table_headers, block.one_table.one_table_headers + [OneTableHeaderValue::FREEWORD_SEARCH])
    self.block = block
  end

  def items
    headers_with_index
  end

  def editable_items_attrs_raw
    m = {}
    attrs = self.block.block_one_table_headers.map do |both|
      m[both.one_table_header.sysname] = {
          'input_type' => both.options[:input_type],
          'user_list' => both.options[:user_list],
          'display_index' => both.sort_index,
      }
    end
    m
  end

  protected
  def attrs_options(attrs)
    { :input_type => attrs['input_type'],
      :user_list => attrs['user_list'] }
  end
end
