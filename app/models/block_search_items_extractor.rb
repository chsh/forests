# encoding: UTF-8
class BlockSearchItemsExtractor

  SZ_MANY_CHECKBOXES = 6

  attr_reader :jquery_enabled

  def initialize(block)
    @block = block
  end
  def render(params, matches = {})
    render_search_items(params, matches)
  end
  private
  # currently arguments have no effects.
  def render_search_items(params, matches)
    result = []
    result << heading_content
    @block.block_one_table_headers.each do |both|
      oth = both.one_table_header
      result << render_search_item(repeating_content, both, oth)
    end
    result << trailing_content
    result.join("\n")
  end
  def render_search_item(source, both, oth)
    source.gsub(/:([a-z_][a-z_\d]*?):/) do |match|
      key = $1
      render_each_key(key, both, oth)
    end
  end
  def render_each_key(key, both, oth)
    case key
    when 'header_label' then oth.label
    when 'form_field' then render_form_field(both, oth)
    when 'header_value' then header_value(both, oth)
    else raise "Unexpected key:#{key}"
    end
  end

  def header_value(both, oth)
    case both.options[:input_type]
    when 'display' then "_#{oth.label}_"
    when 'link' then "<a href=\"id-_ID_.html\">_#{oth.label}_</a>"
    else raise "Unexpected input_type:#{both.options[:input_type]}"
    end
  end

  def render_form_field(both, oth)
    cmd, opts = split_cmd_and_opts both.options[:input_type]
    case cmd
    when 'select' then render_form_field_select(oth, both.options)
    when 'checkbox' then render_form_field_checkbox(oth, both.options)
    when 'text' then render_form_field_text(oth)
    when 'date' then render_form_field_date(oth, opts)
    when 'date_wday'
      warn "DEPRECATION WARNING: date_wday is obsolute. Use date:wday instead."
      render_form_field_date oth, :wday => true
    when /^swl_(\d+)$/
      render_form_field_swl(oth, $1)
    else raise "Unexpected input type:#{both.options[:input_type]}"
    end
  end
  def render_form_field_select(oth, opts)
    if opts[:user_list] =~ /^swl_(\d+)$/
      vals = SearchWordList.find($1).search_words_for_select_or_checkbox
    else
      vals = @block.one_table.distinct_values(oth.sysname).map { |v| [v, v]}
    end
    results = []
    results << <<EOL
<select name="#{oth.sysname}">
<option value="">(選択なし)</option>
EOL
    vals.each do |val|
      results << <<EOL
<option value="#{val[1]}">#{val[0]}</option>
EOL
    end
    results << <<EOL
</select>
EOL
    results.join('')
  end
  def render_form_field_checkbox(oth, opts)
    if opts[:user_list] =~ /^swl_(\d+)$/
      vals = SearchWordList.find($1).search_words_for_select_or_checkbox
    else
      vals = @block.one_table.distinct_values(oth.sysname).map { |v| [v, v]}
    end
    results = vals.map_with_index do |val, index|
      <<EOL
<input type="checkbox" class="ot#{@block.one_table.id}#{oth.sysname}" name="#{oth.sysname}[]" value="#{val[1]}"/>#{val[0]}
EOL
    end
    if vals.size >= SZ_MANY_CHECKBOXES
      @jquery_enabled ||= true
      results << <<EOL
<script>
$(function() {
  $("#ot#{@block.one_table.id}#{oth.sysname}").click(function() {
    var cv = $("#ot#{@block.one_table.id}#{oth.sysname}").attr('checked');
    $("input.ot#{@block.one_table.id}#{oth.sysname}").attr('checked', cv);
  });
});
</script>
<br/>
<span style="font-size: x-small; color: #7f7f7f"><input type="checkbox" id="ot#{@block.one_table.id}#{oth.sysname}"/>すべてのチェックを設定または解除</span>
EOL
    end
    results.join(' ')
  end
  def render_form_field_text(oth)
    <<EOL
<input type="text" name="#{oth.sysname}" value=""/>
EOL
  end
  def render_form_field_date(oth, opts = {})
    ds = []
    if opts[:pc]
      @jquery_enabled ||= true
      ds << <<EOL
<input type="text" name="#{oth.sysname}[f]" value="" id="#{oth.sysname}_f"/>
〜
<input type="text" name="#{oth.sysname}[t]" value="" id="#{oth.sysname}_t"/>
<script>
$(function(){
  $('\##{oth.sysname}_f').datepicker();
  $('\##{oth.sysname}_t').datepicker();
});
</script>
EOL
    else
      ds << select_ymd(oth.sysname, 'f', :select_today => opts[:select_today])
      ds << '〜'
      ds << select_ymd(oth.sysname, 't')
    end
    if opts[:wday]
      ds << "\n<br/>\n"
      ds << wday(oth)
    end
    ds.join("\n")
  end
  WDAYS = [
          [0, '日'], [1, '月'], [2, '火'], [3, '水'],
          [4, '木'], [5, '金'], [6, '土']
  ]
  def wday(oth)
    WDAYS.map do |i, label|
      <<EOL
<input type="checkbox" name="#{oth.sysname}[wd][]" value="#{i}"/> #{label}
EOL
    end.join('&nbsp;')
  end

  def render_form_field_swl(oth, swl_id)
    swl = SearchWordList.find swl_id
    swl.search_words.map do |sw|
      <<EOL
<input type="checkbox" name="#{oth.sysname}[]" value="#{sw.search_value}"/> #{sw.display_value}
EOL
    end.join('&nbsp;')
  end

  def heading_content
    separated_content[0]
  end
  def repeating_content
    separated_content[1]
  end
  def trailing_content
    separated_content[2]
  end
  def separated_content
    @separated_content ||= build_separated_content
  end
  def build_separated_content
    if @block.content =~ /^(.*)<repeat>(.+)<\/repeat>(.*)$/m
      [$1, $2, $3]
    else
      ['', @block.content, '']
    end
  end
  def split_cmd_and_opts(string)
    return [nil, {}] unless string
    args = string.split(':')
    cmd = args.shift
    opts = Hash[*args.map { |arg| [arg.to_sym, true]}.flatten]
    [cmd, opts]
  end
  def select_ymd(name, hk, opts = {})
    if opts[:select_today]
      sdb = SelectDateBuilder.new Date.today
    else
      sdb = SelectDateBuilder.new
    end
    sdb.build "#{name}[#{hk}]"
  end
end
