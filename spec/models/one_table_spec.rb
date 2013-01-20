# encoding: UTF-8
require 'spec_helper'

require 'tempfile'
class LocalUploadedFile
  # The filename, *not* including the path, of the "uploaded" file
  attr_reader :original_filename
  # The content type of the "uploaded" file
  attr_reader :content_type
  def initialize(path, content_type = 'text/plain')
    raise "#{path} file does not exist" unless File.exist?(path)
    @content_type = content_type
    @original_filename = path.sub(/^.*#{File::SEPARATOR}([^#{File::SEPARATOR}]+)$/) { $1 }
    @tempfile = Tempfile.new(@original_filename)
    FileUtils.copy_file(path, @tempfile.path)
  end
  def path #:nodoc:
    @tempfile.path
  end
  alias local_path path
  def method_missing(method_name, *args, &block) #:nodoc:
    @tempfile.send(method_name, *args, &block)
  end
end

describe OneTable do
  before do
    @user = create :user
    @user2 = create :user, :email => 'test2@test2.com'
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
    cc = MongoConnection.class_config['media_keeper']
    @mc_mk = MongoConnection.create :name => cc['name'],
                             :host => cc['host'],
                             :port => cc['port'],
                             :db => cc['db']
    cc = SolrConnection.class_config['default']
    @sc = SolrConnection.create :name => cc['name'],
                                :url => cc['url'],
                                :options => cc['options']
    Delayed::Job.all.each &:destroy
  end

  it 'should replace data with primary keys' do
    ot = @user.one_tables.create :name => 't1pk'
    headers = [['マーカー種別', :string], ['利用日付', :time], ['合計', :integer], ['備考', :text]]
    rows = [
            ['abc', Time.parse('2009/9/30'), 123, 'これは備考です。abcを含みます。'],
            ['いろは', nil, 456, 'これは一つのペンです。'],
            ['xyz', Time.parse('2010/3/21'), 0, 'これは別の例です。'],
            ['ABC', Time.parse('2001/5/10'), -2500, 'これは大文字の例です。ABCが入っています。'],
           ]
    ot.headers = headers
    ot.rows = rows
    ot.rows.should == rows
    oth = ot.one_table_headers[0]
    oth.update_attributes primary_key: true
    # reload
    ot = OneTable.find ot
    ot.rows = [
        ['abc', Time.parse('2009/9/30'), 456, 'これは新しい備考です']
    ]
    ot.rows[0].should == ['abc', Time.parse('2009/9/30'), 456, 'これは新しい備考です']
    ot.rows.size.should == 4
  end

  it "should import a file" do
    ot = @user.one_tables.create :name => 'test1'
    ot.execute_import "#{Rails.root}/spec/files/one_table/test1.xls"
    ot.row_size.should == 2
    names = ot.header_names_by_labels_or_refnames 'タイトル', '説明'
    oth = ot.create_virtual_field :label => 'マルチカラム',
                             :refname => 'multicolumn',
                             :formula => Formula::Join.new(:params => {:fields => names, :delimiter => '/そして/'})
    ot.execute_import "#{Rails.root}/spec/files/one_table/test1.xls"
    ot.rows[1][0].should == 'あのタイトル'
    ot.rows[0][4].should == 'このタイトル/そして/よい説明だと思います。'

    ot.clear_mongo_and_solr_documents
    ot.execute_import "#{Rails.root}/spec/files/one_table/test1-no-hdrs.xls"
    puts "ot.rows.inspect:#{ot.rows.inspect}"
    ot.rows[1][0].should == 'あのタイトルX'
    ot.rows[0][4].should == 'このタイトル/そして/よい説明だと思います。Y'
  end

  it "should import a file with defined headers" do
    ot = @user.one_tables.create :name => 'test1'
    ot.headers = [['タイトル', :text], ['説明', :text], ['regdate', :time], ['quantity', :integer]]
    label2oth = ot.one_table_headers.refmap(&:label)
    label2oth['タイトル'].update_attributes :refname => 'title'
    label2oth['説明'].update_attributes :refname => 'desc'
    ot.execute_import "#{Rails.root}/spec/files/one_table/test1hdr.xls"
    ot.row_size.should == 2
    ot.rows[1][0].should == 'あのタイトル'
    ot.rows[0][1].should == 'よい説明だと思います。'
  end

  it 'should handle invalid file.' do
    ot = @user.one_tables.create :name => 'test1invalidimport'
    ot.send :update_status, 'valid-state'
    lambda {
      ot.execute_import "#{Rails.root}/spec/files/one_table/test2invalid1.xls"
    }.should raise_error
    ot.status(true).should be_nil
    [:class_name, :message].map { |msg| ot.last_error.send msg }.should == [
            'Ole::Storage::FormatError', 'OLE2 signature is invalid'
    ]
    ot.clear_last_error
    ot2 = OneTable.find ot.id
    ot2.last_error.should be_nil
  end

  it "should a process file in background." do
    OneTable.delete_all
    ot = @user.one_tables.create :file => "#{Rails.root}/spec/files/one_table/test1.xls"
    ot.name.should == 'test1.xls'
    ot.status.should == 'preparing-to-import'
    Delayed::Worker.new.work_off.should == [1, 0]
    ot = OneTable.find ot.id
    ot.row_size.should == 2
    ot = OneTable.find ot.id
    ot.status.should be_nil
  end

  it "can i/o rows" do
    ot = @user.one_tables.create :name => 't1'
    headers = [['マーカー種別', :string], ['利用日付', :time], ['合計', :integer], ['備考', :text]]
    rows = [
            ['abc', Time.parse('2009/9/30'), 123, 'これは備考です。abcを含みます。'],
            ['いろは', nil, 456, 'これは一つのペンです。'],
            ['xyz', Time.parse('2010/3/21'), 0, 'これは別の例です。'],
            ['ABC', Time.parse('2001/5/10'), -2500, 'これは大文字の例です。ABCが入っています。'],
           ]
    ot.headers = headers
    ot.header_label_and_types.should == headers
    ot.rows = rows
    ot.rows.should == rows
    ot.find('備考' => 'abc').should == [
            ['abc', Time.parse('2009/9/30'), 123, 'これは備考です。abcを含みます。'],
            ['ABC', Time.parse('2001/5/10'), -2500, 'これは大文字の例です。ABCが入っています。'],
           ]
    ot.find({'備考' => 'abc'}, solr: {rows: 1}).should == [
            ['abc', Time.parse('2009/9/30'), 123, 'これは備考です。abcを含みます。'],
           ]
    ot.find('備考' => ['abc', 'ペン']).should == [
            ['いろは', nil, 456, 'これは一つのペンです。'],
            ['abc', Time.parse('2009/9/30').utc, 123, 'これは備考です。abcを含みます。'],
            ['ABC', Time.parse('2001/5/10').utc, -2500, 'これは大文字の例です。ABCが入っています。'],
           ]
    frs = ot.find({'備考' => 'abc'}, :with_id => true)
    frs.map do |fr|
      fr[:cells]
    end.should == [
            ['abc', Time.parse('2009/9/30'), 123, 'これは備考です。abcを含みます。'],
            ['ABC', Time.parse('2001/5/10'), -2500, 'これは大文字の例です。ABCが入っています。'],
    ]
    rows2 = [
            ['これは備考だよ。i1n2s3を含みます。', 'ichinisan', Time.parse('2011/1/30')],
            ['これは七つのペンです。', 'いろはろう', nil],
            ['これは別のサンプルです。', 'momomo', Time.parse('2010/11/3')]
    ]
    ot.clear_mongo_and_solr_documents
    ot.rows_with_headers rows2,  %w(備考 マーカー種別 利用日付)
    ot.rows.should == [
            ["ichinisan", Time.parse('2011/1/30'), nil, "これは備考だよ。i1n2s3を含みます。"],
            ["いろはろう", nil, nil, "これは七つのペンです。"],
            ["momomo", Time.parse('2010/11/3'), nil, "これは別のサンプルです。"]
    ]
  end

  it "should have #find_with_id" do
    ot = @user.one_tables.create :name => 't1'
    ot.import "#{Rails.root}/spec/files/one_table/test2_import.xls"
    ot.header_label_and_types.should == [["タイトル", :text],
                ["説明", :text],
                ["登録日", :time],
                ["数量", :integer]]
    recs = ot.send(:find_with_id, 'タイトル' => 'あのタイトル')
    recs.size.should == 1
    [[:cells, :id], [:id, :cells]].include?(recs[0].keys).should be_true
    recs[0][:cells].should == ['あのタイトル', 'Not so bad.', Time.parse('2009/12/23'), 200]
    value = recs[0][:id].to_s
    (value =~ /^[0-9a-z]{24}$/).should == 0
  end

  it "should have #record" do
    ot = @user.one_tables.create :name => 'trecord1'
    ot.import "#{Rails.root}/spec/files/one_table/test2_import.xls"
    recs = ot.send(:find_with_id, 'タイトル' => 'あのタイトル')
    mongoid = recs[0][:id]
  end

  it 'should regenerate solr index.' do
    ot = @user.one_tables.create :name => 'trecord2'
    ot.import "#{Rails.root}/spec/files/one_table/test3_import.xls"
    recs = ot.find '説明' => 'よい'
    recs.size.should == 0
    oth = ot.one_table_headers.find_by_label '説明'
    oth.update_attributes :kind => OneTableHeader::KIND_TEXT
    ot.rebuild_solr_index!
    recs = ot.find '説明' => 'よい'
    recs.size.should == 1
  end

  it 'should add virtual field.' do
    ot = @user.one_tables.create :name => 'vf3'
    headers = [['マーカー種別', :string], ['利用日付', :time], ['合計', :integer], ['備考', :text]]
    rows = [
            ['abc', Time.parse('2009/9/30'), 123, 'これは備考です。abcを含みます。'],
            ['いろは', nil, 456, 'これは一つのペンです。'],
            ['xyz', Time.parse('2010/3/21'), 0, 'これは別の例です。'],
            ['ABC', Time.parse('2001/5/10'), -2500, 'これは大文字の例です。ABCが入っています。'],
           ]
    ot.headers = headers
    ot.header_label_and_types.should == headers
    ot.rows = rows
    names = ot.header_names_by_labels_or_refnames 'マーカー種別', '備考'
    oth1 = ot.create_virtual_field :label => 'マルチカラム',
                             :refname => 'multicolumn',
                             :formula => Formula::Join.new(:params => {:fields => names, :delimiter => ':'})
    ot.fill_virtual_field oth1.id, false
    ot.rows[0][4].should == 'abc:これは備考です。abcを含みます。'

    oth2a = ot.create_virtual_field :label => 'マルチカラム2a',
                             :refname => 'multicolumn2a',
                             :formula => Formula::ConvertJoin.new(
                                     :params => {:fields => names, :join_script => 'values.join("/")'}
                             )
    oth2b = ot.create_virtual_field :label => 'マルチカラム2b',
                             :refname => 'multicolumn2b',
                             :formula => Formula::ConvertJoin.new(
                                     :params => {:fields => names, :join_script => 'values.reverse.join("><")'}
                             )
    ot.rows[1][5].should be_nil
    ot.rows[1][6].should be_nil
    ot.fill_virtual_field [oth2a.id, oth2b.id], false
    ot.rows[1][5].should == 'いろは/これは一つのペンです。'
    ot.rows[1][6].should == 'これは一つのペンです。><いろは'
  end

  it "should a process virtual field in background." do
    OneTable.delete_all
    ot = @user.one_tables.create :name => 'vf3'
    headers = [['マーカー種別', :string], ['利用日付', :time], ['合計', :integer], ['備考', :text]]
    rows = [
            ['abc', Time.parse('2009/9/30'), 123, 'これは備考です。abcを含みます。'],
            ['いろは', nil, 456, 'これは一つのペンです。'],
            ['xyz', Time.parse('2010/3/21'), 0, 'これは別の例です。'],
            ['ABC', Time.parse('2001/5/10'), -2500, 'これは大文字の例です。ABCが入っています。'],
           ]
    ot.headers = headers
    ot.header_label_and_types.should == headers
    ot.rows = rows
    names = ot.header_names_by_labels_or_refnames 'マーカー種別', '備考'
    oth = ot.create_virtual_field :label => 'マルチカラム',
                             :refname => 'multicolumn',
                             :formula => Formula::Join.new(:params => {:fields => names, :delimiter => ':'})
    ot.fill_virtual_field oth.id, true
    ot.status.should == 'preparing-to-create-virtual-field'
    Delayed::Worker.new.work_off.should == [1, 0]
    ot.rows[0][4].should == 'abc:これは備考です。abcを含みます。'
    ot.rows[0][0].should == 'abc'
    ot.status(true).should be_nil
  end

  it "should a process virtual field on importing." do
    OneTable.delete_all
    ot = @user.one_tables.create :name => 'vf3'
    headers = [['マーカー種別', :string], ['利用日付', :time], ['合計', :integer], ['備考', :text]]
    ot.headers = headers
    ot.header_label_and_types.should == headers
    names = ot.header_names_by_labels_or_refnames 'マーカー種別', '備考'
    oth = ot.create_virtual_field :label => 'マルチカラム',
                             :refname => 'multicolumn',
                             :formula => Formula::Join.new(:params => {:fields => names, :delimiter => ':'})
    rows = [
            ['abc', Time.parse('2009/9/30'), 123, 'これは備考です。abcを含みます。'],
            ['いろは', nil, 456, 'これは一つのペンです。'],
            ['xyz', Time.parse('2010/3/21'), 0, 'これは別の例です。'],
            ['ABC', Time.parse('2001/5/10'), -2500, 'これは大文字の例です。ABCが入っています。'],
           ]
    ot.rows = rows
    ot.rows[0][0].should == 'abc'
    ot.rows[0][4].should be_nil
    ot.execute_fill_virtual_field
    ot.rows[0][0].should == 'abc'
    ot.rows[0][4].should == 'abc:これは備考です。abcを含みます。'
  end

  it 'should list distinct values by sysname' do
    ot = @user.one_tables.create :name => 'vf3x1'
    headers = [['マーカー種別', :string], ['利用日付', :time], ['合計', :integer], ['備考', :text]]
    rows = [
            ['abc', Time.parse('2009/9/30'), 123, 'これは備考です。abc-xを含みます。'],
            ['abc', Time.parse('2009/8/30'), 124, 'これは備考です。abc-yを含みます。'],
            ['abc', Time.parse('2009/7/30'), 123, 'これは備考です。abc-zを含みます。'],
            ['abc', Time.parse('2009/6/30'), 120, 'これは備考です。abc+zを含みます。'],
            ['abc', Time.parse('2009/5/30'), nil, 'これは備考です。abc+xを含みます。'],
            ['abc', Time.parse('2009/4/30'), 120, 'これは備考です。abc+yを含みます。'],
            ['いろは', nil, 456, 'これは一つのペンです。'],
            ['xyz', Time.parse('2010/3/21'), 0, 'これは別の例Aです。'],
            ['xyz', Time.parse('2010/4/21'), 10, 'これは別の例Bです。'],
            ['xyz', Time.parse('2010/5/21'), 5, 'これは別の例Cです。'],
            ['xyz', Time.parse('2010/6/21'), -10, 'これは別の例Dです。'],
            ['ABC', Time.parse('2001/5/10'), 10, 'これは大文字の例です。ABCが入っています。'],
           ]
    ot.headers = headers
    ot.rows = rows
    name1 = ot.header_names_by_labels_or_refnames('マーカー種別')[0]
    ot.distinct_values(name1).should == ['abc', 'いろは', 'xyz', 'ABC'].sort
    rec = ot.record
    rec.update_attributes 'h0' => 'XYZ', 'h1' => Time.parse('2010/12/31'), 'h2' => 20000, 'h3' => '備考データ'
    ot.distinct_values(name1).should == ['abc', 'いろは', 'xyz', 'ABC'].sort
    ot.distinct_values(name1, true).should == ['abc', 'いろは', 'xyz', 'ABC', 'XYZ'].sort
    ot.distinct_values(name1).should == ['abc', 'いろは', 'xyz', 'ABC', 'XYZ'].sort
    name2 = ot.header_names_by_labels_or_refnames('合計')[0]
    ot.distinct_values(name2).should == [-10, 0, 5, 10, 120, 123, 124, 456, 20000]
  end

  it "should set table access permission." do
    ot = @user.one_tables.create :name => 'test-p1'
    a_user = create :default_user, :login => 'test-a_at_test.com'
    a_user.permissions.size.should == 0
    a_user.permissions.assign ot, :updatable
    a_user.permissions.assigned(ot).updatable?.should be_true
    a_user.permissions.assigned(ot).destroyable?.should_not be_true
  end

  it 'should convert params into solr query.' do
    ot = @user.one_tables.create :name => 'test-conv2solr'
    ot.headers = [['マーカー種別', :string], ['利用日付', :time], ['合計', :integer], ['備考', :text]]
    sq1 = ot.send :hash_to_solr_query, {'ht' => 'テキスト', 'h1' => '2010/1/10'}
    sq1.should == 'テキスト h1_d:[2010-01-09T15:00:00Z TO 2010-01-09T15:00:00Z]'
    sq2 = ot.send :hash_to_solr_query, {'ht' => 'テキスト', 'h1' => {'y' => '2010', 'm' => '1', 'd' => '10'}}
    sq2.should == 'テキスト h1_d:[2010-01-09T15:00:00Z TO 2010-01-09T15:00:00Z]'
    sq3 = ot.send :hash_to_solr_query, {'ht' => 'テキスト', 'h1' => {'f' => '2010/1/10'}}
    sq3.should == 'テキスト h1_d:[2010-01-09T15:00:00Z TO *]'
    sq4 = ot.send :hash_to_solr_query, {'ht' => 'テキスト', 'h1' => {'t' => '2010/1/10'}}
    sq4.should == 'テキスト h1_d:[* TO 2010-01-09T15:00:00Z]'
    sq5 = ot.send :hash_to_solr_query, {'ht' => 'テキスト', 'h1' => {'f' => {'y' => '', 'm' => '', 'd' => ''}, 't' => '2010/1/10'}}
    sq5.should == 'テキスト h1_d:[* TO 2010-01-09T15:00:00Z]'
    sq6 = ot.send :hash_to_solr_query, {'ht' => 'テキスト', 'h1' => {'f' => '', 't' => '2010/1/10'}}
    sq6.should == 'テキスト h1_d:[* TO 2010-01-09T15:00:00Z]'

  end

  it 'should copy instance with headers.' do
    ot = @user.one_tables.create :name => 'vf3'
    headers = [['マーカー種別', :string], ['利用日付', :time], ['合計', :integer], ['備考', :text]]
    rows = [
            ['abc', Time.parse('2009/9/30'), 123, 'これは備考です。abc-xを含みます。'],
            ['abc', Time.parse('2009/8/30'), 124, 'これは備考です。abc-yを含みます。'],
            ['abc', Time.parse('2009/7/30'), 122, 'これは備考です。abc-zを含みます。'],
            ['abc', Time.parse('2009/6/30'), 120, 'これは備考です。abc+zを含みます。'],
            ['abc', Time.parse('2009/5/30'), 129, 'これは備考です。abc+xを含みます。'],
            ['abc', Time.parse('2009/4/30'), 128, 'これは備考です。abc+yを含みます。'],
            ['いろは', nil, 456, 'これは一つのペンです。'],
            ['xyz', Time.parse('2010/3/21'), 0, 'これは別の例Aです。'],
            ['xyz', Time.parse('2010/4/21'), 10, 'これは別の例Bです。'],
            ['xyz', Time.parse('2010/5/21'), 5, 'これは別の例Cです。'],
            ['xyz', Time.parse('2010/6/21'), -1, 'これは別の例Dです。'],
            ['ABC', Time.parse('2001/5/10'), -2500, 'これは大文字の例です。ABCが入っています。'],
    ]
    ot.headers = headers
    ot.one_table_headers[3].formula = Formula::ConvertJoin.new
    ot.one_table_headers[3].formula.params = {
            :delimiter => '/',
            :fields => ['h0', 'h2']
    }
    ot.one_table_headers[3].formula.save
    ot.rows = rows
    ot2 = @user2.one_tables.create :name => 'vf3',
                                   :one_table_headers_from => ot
    oths = ot.one_table_headers
    oths.map { |oth| oth.one_table_id }.uniq.should == [ot.id]
    ot2hs = ot2.one_table_headers
    ot2hs.map { |oth| oth.one_table_id }.uniq.should == [ot2.id]
    oths_attrs = oths.map { |oth| remove_active_record_specific_attrs(oth, 'one_table_id') }
    ot2hs_attrs = ot2hs.map { |oth| remove_active_record_specific_attrs(oth, 'one_table_id') }
    oths_attrs.should == ot2hs_attrs
    ot2hs[3].formula.class.should == Formula::ConvertJoin
    ot2hs[3].formula.params.should == {:delimiter => '/', :fields => ['h0', 'h2']}
  end

  it 'can hold template.xls' do
    ot0 = @user.one_tables.create :name => 'vf3templatexls',
                                  :template_file => 'spec/files/one_table/one-table-template-file.xls'
    ot1 = OneTable.find ot0.id
    (ot1.template_file.content == File.open('spec/files/one_table/one-table-template-file.xls', 'rb').read).should be_true
    ot1.update_attributes :template_file => 'spec/files/one_table/one-table-template-file-2.xls'
    ot2 = OneTable.find ot0.id
    (ot2.template_file.content == File.open('spec/files/one_table/one-table-template-file-2.xls', 'rb').read).should be_true
    ot2.update_attributes :template_file => LocalUploadedFile.new('spec/files/one_table/one-table-template-file-3.xls')
    ot3 = OneTable.find ot2.id
    (ot3.template_file.content == File.open('spec/files/one_table/one-table-template-file-3.xls', 'rb').read).should be_true
  end

  it 'should change headers structure.' do
    ot = @user.one_tables.create :name => 'vf-hsc3'
    headers = [['マーカー種別', :string], ['利用日付', :time], ['合計', :integer], ['備考', :text]]
    ot.headers = headers
    ot.one_table_headers(true).map { |oth| [oth.label, oth.kind, oth.sysname] }.should ==
            [['マーカー種別', 1, 'h0'], ['利用日付', 3, 'h1'], ['合計', 4, 'h2'], ['備考', 2, 'h3']]
    headers2 = [['新規キー', :text], ['利用日付', :time], ['詳細', :text], ['マーカー種別', :string]]
    ot.headers = headers2
    ot.one_table_headers(true).map { |oth| [oth.label, oth.kind, oth.sysname, oth.index] }.should ==
            [['マーカー種別', 1, 'h0', 0], ['利用日付', 3, 'h1', 1], ['新規キー', 2, 'h4', 2], ['詳細', 2, 'h5', 3]]
    ot.append_headers [['追加キー', :text], ['利用日付', :time]]
    ot.one_table_headers(true).map { |oth| [oth.label, oth.kind, oth.sysname] }.should ==
            [['マーカー種別', 1, 'h0'], ['利用日付', 3, 'h1'], ['新規キー', 2, 'h4'], ['詳細', 2, 'h5'],
             ['追加キー', 2, 'h6']]
    ot.append_headers [['詳細', :text], ['マーカー種別', :string]]
    ot.one_table_headers(true).map { |oth| [oth.label, oth.kind, oth.sysname] }.should ==
            [['マーカー種別', 1, 'h0'], ['利用日付', 3, 'h1'], ['新規キー', 2, 'h4'], ['詳細', 2, 'h5'],
             ['追加キー', 2, 'h6']]
    # TODO: how to process exit
  end

  it 'should treat multiple valued field correctly.' do
    ot = @user.one_tables.create :name => 'mvfc'
    headers = [['マーカー種別', :string], ['利用日付', :time], ['合計', :integer], ['備考', :text]]
    ot.headers = headers
    oths = ot.one_table_headers(true)
    oths[0].update_attributes :multiple => true
    rows = [
            ['abc', Time.parse('2009/9/30'), 123, 'これは備考です。abc-xを含みます。'],
            ['abc', Time.parse('2009/8/30'), 124, 'これは備考です。abc-yを含みます。'],
            ['abc', Time.parse('2009/7/30'), 122, 'これは備考です。abc-zを含みます。'],
            ['abc', Time.parse('2009/6/30'), 120, 'これは備考です。abc+zを含みます。'],
            ['abc', Time.parse('2009/5/30'), 129, 'これは備考です。abc+xを含みます。'],
            ['abc', Time.parse('2009/4/30'), 128, 'これは備考です。abc+yを含みます。'],
            ['いろは', nil, 456, 'これは一つのペンです。'],
            ['xyz', Time.parse('2010/3/21'), 0, 'これは別の例Aです。'],
            ['xyz', Time.parse('2010/4/21'), 10, 'これは別の例Bです。'],
            ['xyz', Time.parse('2010/5/21'), 5, 'これは別の例Cです。'],
            ['xyz', Time.parse('2010/6/21'), -1, 'これは別の例Dです。'],
            [['ABC', 'def'], Time.parse('2001/5/10'), -2500, 'これは大文字の例です。ABCが入っています。'],
    ]
    ot.rows = rows
    hits1 = ot.find('h0' => 'def')
    (hits1 == [[['ABC', 'def'], Time.parse('2001/5/10'), -2500, 'これは大文字の例です。ABCが入っています。']]).should be_true
    hits2 = ot.find('h0' => 'ABC')
    (hits2 == [[['ABC', 'def'], Time.parse('2001/5/10'), -2500, 'これは大文字の例です。ABCが入っています。']]).should be_true
  end

  it 'should copy instance with all attributes.' do
    ot = @user.one_tables.create :name => 'sciwaa'
    headers = [['マーカー種別', :string], ['利用日付', :time], ['合計', :integer], ['備考', :text]]
    ot.headers = headers
    oths = ot.one_table_headers(true)
    oths[0].update_attributes :multiple => true
    oths[1].create_model_comment :content => {:comment =>'テストコメント'}
    rows = [
            ['abc', Time.parse('2009/9/30'), 123, 'これは備考です。abc-xを含みます。'],
            ['abc', Time.parse('2009/8/30'), 124, 'これは備考です。abc-yを含みます。'],
            ['abc', Time.parse('2009/7/30'), 122, 'これは備考です。abc-zを含みます。'],
            ['abc', Time.parse('2009/6/30'), 120, 'これは備考です。abc+zを含みます。'],
            ['abc', Time.parse('2009/5/30'), 129, 'これは備考です。abc+xを含みます。'],
            ['abc', Time.parse('2009/4/30'), 128, 'これは備考です。abc+yを含みます。'],
            ['いろは', nil, 456, 'これは一つのペンです。'],
            ['xyz', Time.parse('2010/3/21'), 0, 'これは別の例Aです。'],
            ['xyz', Time.parse('2010/4/21'), 10, 'これは別の例Bです。'],
            ['xyz', Time.parse('2010/5/21'), 5, 'これは別の例Cです。'],
            ['xyz', Time.parse('2010/6/21'), -1, 'これは別の例Dです。'],
            [['ABC', 'def'], Time.parse('2001/5/10'), -2500, 'これは大文字の例です。ABCが入っています。'],
    ]
    ot.rows = rows
    ot2 = ot.copy_instance
    oths = ot2.one_table_headers
    oths.map(&:label).should == ['マーカー種別', '利用日付', '合計', '備考']
    oths.map(&:model_comment).map { |mc| mc.content if mc }.should == [nil, {:comment => 'テストコメント'}, nil, nil]
  end

  it 'should detect file fields.' do
    ot = @user.one_tables.create :name => 'sciwaa-media'
    headers = [['マーカー種別', :string], ['利用日付', :time], ['画像', :image]]
    ot.headers = headers
    ot.rows = [['abc', Time.parse('2009/9/30'), 'spec/files/one_table/left_bottom_h2.gif']]
    ot = OneTable.find(ot.id) # reload instance
    ot.file_fields?.should be_true
    row = ot.rows[0]
    h = row[2]
    h.path('/metadata/width').should == 364
    h.path('/metadata/height').should == 52
    mkey = h.path('/value')
    gf = GridFile.new(@mc_mk.remote_connection, "ot#{ot.id}")
    gf.exist?(mkey).should be_true
    c = nil
    gf.open(mkey) do |gs|
      c = gs.read
    end
    (c == File.open('spec/files/one_table/left_bottom_h2.gif', 'rb').read).should be_true
  end

  it 'should find rows by options.' do
    ot = @user.one_tables.create :name => 'mvf_find_rows'
    headers = [['マーカー種別', :string], ['利用日付', :time], ['合計', :integer], ['備考', :text]]
    ot.headers = headers
    rows = [
            ['abc', Time.parse('2009/9/30'), 123, 'これは備考です。abc-xを含みます。'],
            ['abc', Time.parse('2009/8/30'), 124, 'これは備考です。abc-yを含みます。'],
            ['abc', Time.parse('2009/7/30'), 122, 'これは備考です。abc-zを含みます。'],
            ['abc', Time.parse('2009/6/30'), 120, 'これは備考です。abc+zを含みます。'],
            ['abc', Time.parse('2009/5/30'), 129, 'これは備考です。abc+xを含みます。'],
            ['abc', Time.parse('2009/4/30'), 128, 'これは備考です。abc+yを含みます。'],
            ['いろは', nil, 456, 'これは一つのペンです。'],
            ['xyz', Time.parse('2010/3/21'), 0, 'これは別の例Aです。'],
            ['xyz', Time.parse('2010/4/21'), 10, 'これは別の例Bです。'],
            ['xyz', Time.parse('2010/5/21'), 5, 'これは別の例Cです。'],
            ['xyz', Time.parse('2010/6/21'), -1, 'これは別の例Dです。'],
    ]
    ot.rows = rows
    rows0 = ot.rows limit: 1
    rows0.size.should == 1
    rows0[0][2].should == 123
    rows1 = ot.rows limit: 1, offset: 6
    rows1[0][0].should == 'いろは'
  end

  it 'should export as various formats.' do
    ot = @user.one_tables.create :name => 'ot_for_export'
    headers = [['マーカー種別', :string], ['利用日付', :time], ['合計', :integer], ['備考', :text]]
    ot.headers = headers
    rows = [
            ['abc', Time.parse('2009/9/30'), 123, 'これは備考です。abc-xを含みます。'],
            ['abc', Time.parse('2009/8/30'), 124, 'これは備考です。abc-yを含みます。'],
            ['abc', Time.parse('2009/7/30'), 122, 'これは備考です。abc-zを含みます。'],
            ['abc', Time.parse('2009/6/30'), 120, 'これは備考です。abc+zを含みます。'],
            ['abc', Time.parse('2009/5/30'), 129, 'これは備考です。abc+xを含みます。'],
            ['abc', Time.parse('2009/4/30'), 128, 'これは備考です。abc+yを含みます。'],
            ['いろは', nil, 456, 'これは一つのペンです。'],
            ['xyz', Time.parse('2010/3/21'), 0, 'これは別の例Aです。'],
            ['xyz', Time.parse('2010/4/21'), 10, 'これは別の例Bです。'],
            ['xyz', Time.parse('2010/5/21'), 5, 'これは別の例Cです。'],
            ['xyz', Time.parse('2010/6/21'), -1, 'これは別の例Dです。'],
    ]
    ot.rows = rows
#    ot = OneTable.find ot.id
    csv_utf8_bin = ot.content_for(:csv).force_encoding('BINARY')
    expected_csv_utf8 = File.open('spec/files/one_table/csv-utf8.data', 'rb').read
    csv_utf8_bin.should == expected_csv_utf8

    csv_cp932_bin = ot.content_for(:csv, target: 'windows').force_encoding('BINARY')
    expected_csv_cp932 = File.open('spec/files/one_table/csv-cp932.data', 'rb').read
    csv_cp932_bin.should == expected_csv_cp932

    tsv_utf8_bin = ot.content_for(:tsv).force_encoding('BINARY')
    expected_tsv_utf8 = File.open('spec/files/one_table/tsv-utf8.data', 'rb').read
    tsv_utf8_bin.should == expected_tsv_utf8

    tsv_cp932_bin = ot.content_for(:tsv, target: 'windows').force_encoding('BINARY')
    expected_tsv_cp932 = File.open('spec/files/one_table/tsv-cp932.data', 'rb').read
    tsv_cp932_bin.should == expected_tsv_cp932

    csv_shrink_utf8_bin = ot.content_for(:csv, fields: ['マーカー種別', '合計']).force_encoding('BINARY')
    expected_csv_shrink_utf8 = File.open('spec/files/one_table/csv-shrink-utf8.data', 'rb').read
    csv_shrink_utf8_bin.should == expected_csv_shrink_utf8
  end
  after do
    @mc.destroy
    @mc_gfs.destroy
    @mc_mk.destroy
    @sc.destroy
  end

  private
  def remove_active_record_specific_attrs(ar, *other_keys)
    other_keys = [other_keys].flatten
    attrs = ar.attributes.clone
    attrs.delete 'id'
    attrs.delete 'created_at'
    attrs.delete 'updated_at'
    other_keys.each do |other_key|
      attrs.delete other_key
    end
    attrs
  end
end
