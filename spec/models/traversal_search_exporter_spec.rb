# -*- encoding: UTF-8 -*-

require 'spec_helper'

describe TraversalSearchExporter do
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
    cc = MongoConnection.class_config['media_keeper']
    @mc_mk = MongoConnection.create :name => cc['name'],
                             :host => cc['host'],
                             :port => cc['port'],
                             :db => cc['db']
    cc = SolrConnection.class_config['default']
    @sc = SolrConnection.create :name => cc['name'],
                                :url => cc['url'],
                                :options => cc['options']

  end
  after(:each) do
    @mc.destroy
    @mc_gfs.destroy
    @mc_mk.destroy
    @sc.destroy
    @user.destroy
  end

=begin
  it 'should export one_table data with options.' do
    ot = @user.one_tables.create :name => 't1tse'
    headers = [['マーカー種別', :string], ['利用日付', :time], ['合計', :integer], ['備考', :text]]
    rows = [
        ['いろは', nil, 456, 'これは一つのペンです。'],
        ['ABC', Time.parse('2001/5/10'), -2500, "これは\t大文字の例です。\nABCが\n入っています。"],
    ]
    ot.headers = headers
    ot.header_label_and_types.should == headers
    ot.rows = rows
    TraversalSearchOption.create one_table_id: ot.id,
        fields_map: {
            department: 0,
            course: 1,
            title: 2,
            desc: 3
        },
        url_format: {
            pattern: 'http://example.com/pat-[1].html'
        }

    tsv_file = Tempfile.new('tsv')
    options_file = Tempfile.new('options')
#    sleep 1.5
    TraversalSearchExporter.new(ot).export(tsv_file, options_file)
    tsv_file.close; options_file.close
    content = File.read(tsv_file.path)
    puts content
    rows = content.gsub(/\n+$/, '').split(/\n/).map { |r| r.split(/\t/) }
    rows.size.should == 2
    rows[0].should == ['いろは', '', '456', 'これは一つのペンです。']
    [0, 2, 3].map { |i| rows[1][i] }.should == ['ABC', '-2500', 'これは 大文字の例です。 ABCが 入っています。']
    Time.parse(rows[1][1]) == Time.parse('2001/5/10')
    YAML.load_file(options_file).should == {
        fields_map: {
            department: 0,
            course: 1,
            title: 2,
            desc: 3
        },
        url_format: {
            pattern: 'http://example.com/pat-[1].html'
        }
    }
  end
=end
end
