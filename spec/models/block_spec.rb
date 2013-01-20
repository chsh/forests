# encoding: UTF-8
require 'spec_helper'

describe Block do
  before(:each) do
    @user = create :user
    cc = MongoConnection.class_config['default']
    @mc = MongoConnection.create :name => cc['name'],
                             :host => cc['host'],
                             :port => cc['port'],
                             :db => cc['db']
    cc = MongoConnection.class_config['default_gridfs']
    @mc_gfs = MongoConnection.create :name => cc['name'],
                             :host => cc['host'],
                             :port => cc['port'],
                             :db => cc['db']
    cc = SolrConnection.class_config['default']
    @sc = SolrConnection.create :name => cc['name'],
                                :url => cc['url'],
                                :options => cc['options']
  end

  it "should render one_table record" do
    ot = @user.one_tables.create :name => 't1'
    headers = [['マーカー種別', :string], ['利用日付', :time], ['合計', :integer], ['備考', :text]]
    rows = [
            ['abc', Time.parse('2009/9/30'), 123, 'これは備考です。abcを含みます。'],
            ['いろは', Time.parse('2009/1/2'), 456, 'これは一つのペンです。'],
            ['xyz', Time.parse('2010/3/21'), 0, 'これは別の例です。'],
            ['ABC', Time.parse('2001/5/10'), -2500, 'これは大文字の例です。ABCが入っています。'],
           ]
    ot.headers = headers
    ot.rows = rows
    block = @user.blocks.create :name => 'b1', :content => '<tag>_合計_</tag>',
                                :conditions => 'ID=?', :one_table_id => ot.id
    rec0a = ot.send(:find_with_id, '備考' => '大文字の例')[0]
    block.render('ID' => rec0a[:id]).should == '<tag>-2500</tag>'
    rec0b = ot.send(:find_with_id, 'マーカー種別' => 'いろは')[0]
    block.render('ID' => rec0b[:id]).should == '<tag>456</tag>'
    block2 = @user.blocks.create :name => 'b1', :content => '<tag>_合計_</tag>',
                                :conditions => 'マーカー種別=?', :one_table_id => ot.id
    block2.render('マーカー種別' => 'xyz').should == '<tag>0</tag>'
  end

  it "should render without one_table record" do
    block = @user.blocks.create :name => 'b-wo-ot', :content => '<tag>結果テキスト</tag>'
    block.render.should == '<tag>結果テキスト</tag>'
  end

  it "should render one_table record with repeated attributes." do
    ot = @user.one_tables.create :name => 't1'
    headers = [['マーカー種別', :string], ['ラベル', :string], ['合計', :integer], ['備考', :text]]
    rows = [
            ['abc', 'ラベル1', 1234, 'これは備考です。1abcを含みます。'],
            ['abc', 'あいう2', 123, 'これは備考です。2abcを含みます。'],
            ['abc', 'あいう2', 321, 'これは備考です。X2abcを含みます。'],
            ['abc', '漢字3', 456, 'これは備考です。漢字3aを含みます。'],
            ['abc', '漢字3', 999, 'これは備考です。漢字3bを含みます。'],
            ['abc', '漢字3', 876, 'これは備考です。漢字3cを含みます。'],
            ['いろは', '政治', 789, 'これは一つのペンです。'],
            ['いろは', '文化', 999, 'これは二つの万年筆です。'],
            ['いろは', '教養', 101, 'これは三つの鉛筆です。'],
            ['xyz', Time.parse('2010/3/21'), 0, 'これは別の例です。'],
            ['ABC', Time.parse('2001/5/10'), -2500, 'これは大文字の例です。ABCが入っています。'],
           ]
    ot.headers = headers
    ot.rows = rows
    block = @user.blocks.create :name => 'b12', :content => '<tag repeat="_ラベル_">_ラベル_<b repeat="_合計_">_合計_</b></tag>',
                                :conditions => 'マーカー種別=?', :one_table_id => ot.id
    result = block.render('マーカー種別' => 'abc').strip.gsub(/\s*\n+\s*/, '')
    result.should == '<tag>ラベル1<b>1234</b></tag><tag>あいう2<b>123</b><b>321</b></tag><tag>漢字3<b>456</b><b>999</b><b>876</b></tag>'
  end
  it 'should render form html.' do
    src_content = '<form><input type="text" name="ho"></input></form>'
    ot = @user.one_tables.create :name => 't1'
    headers = [['マーカー種別', :string], ['ラベル', :string], ['合計', :integer], ['備考', :text]]
    rows = []
    ot.headers = headers; ot.rows = rows
    block = @user.blocks.create :name => 'b13', :content => src_content,
                                :one_table_id => ot.id, :kind => Block::KIND_FORM
    block.render(nil).should == src_content
  end
  it "should render sorted one_table records with repeated attributes." do
    ot = @user.one_tables.create :name => 't1rs'
    headers = [['マーカー種別', :string], ['ラベル', :string], ['合計', :integer], ['備考', :text]]
    rows = [
            ['abc', '教養', 101, 'これは三つの鉛筆です。'],
            ['abc', 'ABC', 0, 'これは別の例です。'],
            ['abc', 'ラベル1', 1234, 'これは備考です。1abcを含みます。'],
            ['abc', 'あいう2', 123, 'これは備考です。2abcを含みます。'],
            ['abc', 'あいう2', 321, 'これは備考です。X2abcを含みます。'],
            ['abc', 'ABC', -100, 'これは別の例です。'],
            ['xyz', nil, -100, 'これは別の例(nil)です。'],
            ['xyz', 'いろは', 100, 'これは別の例(いろは)です。'],
           ]
    ot.headers = headers
    ot.rows = rows
    block = @user.blocks.create :name => 'b12', :content => '<tag repeat="_ラベル_">_ラベル_<b repeat="_合計_">_合計_</b></tag>',
                                :conditions => 'マーカー種別=?', :one_table_id => ot.id, :order => 'ラベル asc, 合計 desc'
    result = block.render('マーカー種別' => 'abc').strip.gsub(/\s*\n+\s*/, '')
    expected = <<EOL
<tag>ABC
  <b>0</b>
  <b>-100</b>
</tag>
<tag>あいう2
  <b>321</b>
  <b>123</b>
</tag>
<tag>ラベル1
  <b>1234</b>
</tag>
<tag>教養
  <b>101</b>
</tag>
EOL
    result.should == expected.strip.gsub(/\s*\n+\s*/, '')

    block2 = @user.blocks.create :name => 'b123', :content => '<tag repeat="_ラベル_">_ラベル_</tag>',
                                :conditions => 'マーカー種別=?', :one_table_id => ot.id, :order => 'ラベル asc'
    result2 = block2.render('マーカー種別' => 'xyz').strip.gsub(/\s*\n+\s*/, '')
    expected2 = <<EOL
<tag>いろは</tag>
EOL
    result2.should == expected2.strip.gsub(/\s*\n+\s*/, '')
  end

  it "should render with one_table fields." do
    ot = @user.one_tables.create :name => 't1oth1'
    headers = [['マーカー種別', :string], ['ラベル', :string], ['合計', :integer], ['備考', :text]]
    rows = [
            ['abc', '教養', 101, 'これは三つの鉛筆です。'],
            ['abc', 'ABC', 0, 'これは別の例です。'],
            ['abc', 'ラベル1', 1234, 'これは備考です。1abcを含みます。'],
            ['abc', 'あいう2', 123, 'これは備考です。2abcを含みます。'],
            ['abc', 'あいう2', 321, 'これは備考です。X2abcを含みます。'],
            ['abc', 'ABC', -100, 'これは別の例です。'],
            ['xyz', nil, -100, 'これは別の例(nil)です。'],
            ['xyz', 'いろは', 100, 'これは別の例(いろは)です。'],
           ]
    ot.headers = headers
    ot.rows = rows
    block = @user.blocks.create :name => 'b1oth1', :content => '<div id="wholeblock"><repeat><th>:header_label:</th><td>:form_field:</td></repeat></div>',
                                :conditions => 'マーカー種別=?', :one_table_id => ot.id, :order => 'ラベル asc, 合計 desc',
                                :kind => Block::KIND_SEARCH_ITEMS, :content_type => 'text/html'
    oths = ot.one_table_headers.refmap(&:label)
    o3 = ['ラベル', '備考', 'マーカー種別'].map { |label| oths[label] }
    block.search_items = {
            o3[0].id.to_s => { 'display_index' => 1, 'input_type' => 'text'},
            o3[1].id.to_s => { 'display_index' => 2, 'input_type' => 'text'},
            o3[2].id.to_s => { 'display_index' => 3, 'input_type' => 'select'}
    }
    block.save
    block = Block.find block.id

    expected = <<EOL
<div id="wholeblock">
<th>ラベル</th><td><input type="text" name="#{o3[0].sysname}" value=""/></td>
<th>備考</th><td><input type="text" name="#{o3[1].sysname}" value=""/></td>
<th>マーカー種別</th>
<td>
<select name="#{o3[2].sysname}">
<option value="">(選択なし)</option>
<option value="abc">abc</option>
<option value="xyz">xyz</option>
</select>
</td>
</div>
EOL
    block.render.strip.gsub(/\s*\n+\s*/, '').should == expected.strip.gsub(/\s*\n+\s*/, '')

    block.content = '<th>:header_label:</th><td>:form_field:</td>'
    block.save
    expected2 = <<EOL
<th>ラベル</th><td><input type="text" name="#{o3[0].sysname}" value=""/></td>
<th>備考</th><td><input type="text" name="#{o3[1].sysname}" value=""/></td>
<th>マーカー種別</th>
<td>
<select name="#{o3[2].sysname}">
<option value="">(選択なし)</option>
<option value="abc">abc</option>
<option value="xyz">xyz</option>
</select>
</td>
EOL
    block.render.strip.gsub(/\s*\n+\s*/, '').should == expected2.strip.gsub(/\s*\n+\s*/, '')

    block.search_items = {
            o3[0].id.to_s => { 'display_index' => 1, 'input_type' => 'display'},
            o3[1].id.to_s => { 'display_index' => 2, 'input_type' => 'link'}
    }
    block.content = "<div id=\"wholeblock\"><repeat>\n<th>:header_label:</th>\n<td>:header_value:</td>\n</repeat>\n</div>"
    block.kind = Block::KIND_LIST_DISPLAY_ITEMS
    block.save
    block = Block.find block.id
    expected3 = <<EOL
<div id="wholeblock">
<th>ラベル</th><td>_#{o3[0].label}_</td>
<th>備考</th><td><a href="id-_ID_.html">_#{o3[1].label}_</a></td>
</div>
EOL
    block.send(:render_display_items).strip.gsub(/\s*\n+\s*/, '').should == expected3.strip.gsub(/\s*\n+\s*/, '')
  end
  it "should render paging records." do
    ot = @user.one_tables.create :name => 'tpg1'
    headers = [['マーカー種別', :string], ['ラベル', :string], ['合計', :integer], ['備考', :text], ['公開日', :time]]
    rows = [
            ['abc', 'ラベル1', 1234, 'これは備考です。1abcを含みます。', Time.parse('2010/1/10')],
            ['abc', 'あいう2.1', 123, 'これは備考です。2abcを含みます。', Time.parse('2010/10/1')],
            ['abc', 'あいう2.5', 321, 'これは備考です。X2abcを含みます。', Time.parse('2009/12/31')],
            ['abc', '漢字3', 456, 'これは備考です。漢字3aを含みます。', Time.parse('2010/5/20')],
            ['abc', '漢字3', 999, 'これは備考です。漢字3bを含みます。', nil],
            ['abc', '漢字3', 876, 'これは備考です。漢字3cを含みます。', Time.parse('2000/1/15')],
            ['いろは', '政治', 789, 'これは一つのペンです。', nil],
            ['いろは', '文化', 999, 'これは二つの万年筆です。', nil],
            ['いろは', '教養', 101, 'これは三つの鉛筆です。', Time.parse('2010/1/11')],
            ['xyz', Time.parse('2010/3/21'), 0, 'これは別の例です。', nil],
            ['ABC', '伊藤園', -2500, 'これは大文字の例です。ABCが入っています。', Time.parse('2011/8/7')],
           ]
    ot.headers = headers
    ot.rows = rows
    block = @user.blocks.create :name => 'bpr12', :content => '<tag>_マーカー種別_ _合計_ _ラベル_</tag>',
                                :conditions => '', :one_table_id => ot.id
    res1 = block.render('page' => '2', 'limit' => '3')
    res1.should == '<tag>abc 456 漢字3</tag><tag>abc 999 漢字3</tag><tag>abc 876 漢字3</tag>'
    res1.metadata[:prev_page].should == "<a href='?limit=3&page=1'>前のページ</a>"
    res2 = block.render('page' => '2', 'limit' => '4', 'h0' => 'abc', 'em' => '京')
    res2.metadata[:next_page].should == ""
    res2.metadata[:prev_page].should == "<a href='?em=%E4%BA%AC&h0=abc&limit=4&page=1'>前のページ</a>"
    res2.metadata[:start_at].to_i.should == 5
    res2.metadata[:end_at].to_i.should == 6
    res2.metadata[:start_to_end].should == "5件目から6件目を表示しています。"
    res3 = block.render('page' => '1', 'limit' => '3', 'h4' => { 'f' => '2010/6/1' }, 'em' => '京')
    res3.should == '<tag>abc 123 あいう2.1</tag><tag>ABC -2500 伊藤園</tag>'
    res4 = block.render('page' => '1', 'limit' => '10', 'h4' => { 'wd' => ['1', '4'] }, 'em' => '京')
    res4.should == '<tag>いろは 101 教養</tag><tag>abc 321 あいう2.5</tag><tag>abc 456 漢字3</tag>'
    res5 = block.render('page' => '1', 'limit' => '10', 'h4' => { 'wd' => ['1', '4'], 't' => '2010/4/1' }, 'em' => '京')
    res5.should == '<tag>いろは 101 教養</tag><tag>abc 321 あいう2.5</tag>'
    res5.metadata[:rec_size_msg].should == '2件見つかりました。'
    res6 = block.render('page' => '1', 'limit' => '10', 'h4' => { 'wd' => ['1', '4'], 'f' => '2010/1/1', 't' => '2010/4/1' }, 'em' => '京')
    res6.should == '<tag>いろは 101 教養</tag>'
    res7 = block.render('page' => '1', 'limit' => '10', 'h4' => { 'f' => '2020/12/31' })
    res7.metadata[:rec_size_msg].should == '1件も見つかりませんでした。'
    res7.metadata[:start_to_end].should == ""
  end

  it 'should hold option values within AdminOption instance.' do
    block = @user.blocks.create :name => 'b-wo-ot-testing', :content => '<tag>結果テキスト</tag>'
    block.admin_options.should == {}
    block.admin_options[:theme] = 'default-classic'
    ao1 = AdminOption.find block.admin_option.id
    ao1.attrs.should == {}
    block.save
    ao2 = AdminOption.find block.admin_option.id
    ao2.attrs.should == { 'theme' => 'default-classic' }
    block.show_in_menu?.should == false
    block.update_attributes :show_in_menu => '1'
    b2 = Block.find block.id
    b2.show_in_menu?.should == true
  end
  it 'should hold description within admin_option.' do
    block = @user.blocks.create :name => 'b-wo-ot-testing', :content => '<tag>結果テキスト</tag>'
    block.description.should be_nil
    block.description = 'Hello, Desc.'
    b1 = Block.find block.id
    b1.description.should be_nil
    block.save
    b2 = Block.find block.id
    b2.description.should == 'Hello, Desc.'
  end
=begin
  it "should copy block_one_table_headers." do
    ot1 = @user.one_tables.create :name => 't1oth1'
    headers1 = [['マーカー種別', :string], ['ラベル', :string], ['合計', :integer], ['備考', :text]]
    rows1 = [
            ['abc', '教養', 101, 'これは三つの鉛筆です。'],
            ['abc', 'ABC', 0, 'これは別の例です。'],
            ['abc', 'ラベル1', 1234, 'これは備考です。1abcを含みます。'],
            ['abc', 'あいう2', 123, 'これは備考です。2abcを含みます。'],
            ['abc', 'あいう2', 321, 'これは備考です。X2abcを含みます。'],
            ['abc', 'ABC', -100, 'これは別の例です。'],
            ['xyz', nil, -100, 'これは別の例(nil)です。'],
            ['xyz', 'いろは', 100, 'これは別の例(いろは)です。'],
           ]
    ot1.headers = headers1
    ot1.rows = rows1
    block1 = @user.blocks.create :name => 'b1oth1', :content => '<h1>Heading One</h1>',
                                :conditions => 'マーカー種別=?', :one_table_id => ot1.id, :order => 'ラベル asc, 合計 desc',
                                :kind => Block::KIND_SEARCH_ITEMS, :content_type => 'text/html'
    oths1 = ot1.one_table_headers.refmap(&:sysname).merge 'ht' => OneTableHeaderValue::FREEWORD_SEARCH
    block1.search_items = {
            oths1['h3'].id => { 'input_type' => 'text', 'display_index' => '1' },
            oths1['ht'].id => { 'input_type' => 'checkbox', 'user_list' => 'swl_21', 'display_index' => '2' }
    }
    block1.save

    ot2 = @user.one_tables.create :name => 't1oth2'
    headers2 = [['マーカー種別', :string], ['ラベル', :string], ['合計', :integer], ['備考', :text]]
    ot2.headers = headers2
    block2 = @user.blocks.create :name => 'b1oth2', :content => '<h1>Heading One</h1>',
                                :conditions => 'マーカー種別=?', :one_table_id => ot2.id, :order => 'ラベル asc, 合計 desc',
                                :kind => Block::KIND_SEARCH_ITEMS, :content_type => 'text/html'
    block2.block_one_table_headers.should == []
    block1r = Block.find block1.id
    block2.search_items_raw = block1r.search_items_raw
    block2.save
    block2r = Block.find block2.id
    block2r.block_one_table_headers.size.should == 2
    both0 = block2r.block_one_table_headers[0]
    both0.one_table_header.sysname.should == 'h3'
    both0.one_table_header.one_table_id.should == ot2.id
    both1 = block2r.block_one_table_headers[1]
    both1.options.should =={ :input_type => 'checkbox', :user_list => 'swl_21' }
  end
=end
end
