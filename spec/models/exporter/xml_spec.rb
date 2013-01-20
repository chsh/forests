# encoding: UTF-8
require 'spec_helper'

describe Exporter::XML do
  before(:each) do
  end

  it 'should process valid one table.' do
    @user = create :inactive_user
    cc = MongoConnection.class_config['default']
    @mc = MongoConnection.create :name => cc['name'],
                             :host => cc['host'],
                             :port => cc['port'],
                             :db => cc['db']
    cc = SolrConnection.class_config['default']
    @sc = SolrConnection.create :name => cc['name'],
                                :url => cc['url'],
                                :options => cc['options']
    ot = @user.one_tables.create :name => 'sciwaa'
    headers = [['マーカー種別', :string], ['利用日付', :time], ['合計', :integer], ['備考', :text]]
    ot.headers = headers
    oths = ot.one_table_headers(true)
    oths[0].update_attributes :multiple => true
    oths[1].create_model_comment :content => {'link_key' => 'comment'}
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
    exp = Exporter::XML.new
    xml = exp.export(ot.one_table_headers, ot.records, :id_url_base => 'http://test.com/detail-#.html')
    # regulate mongoid for comparing
    xml.gsub!(/\b[a-f0-9]{24}\b/, '@')
    expected_xml = File.read('spec/files/exporter/xml/exp01.xml').gsub(/\b[a-f0-9]{24}\b/, '@')
    equal_as_xml(expected_xml, xml).should be_true
  end

  private
  def equal_as_xml(left, right)
    left_x = Nokogiri::XML(left.to_s)
    right_x = Nokogiri::XML(right.to_s)
    compare_element(left_x.root, right_x.root)
  end
  def compare_element(left_elm, right_elm)
    raise "Name unmatch: left:#{left_elm.name}, right:#{right_elm.name}" unless left_elm.name == right_elm.name
    raise "Attributes unmatch: left:#{left_elm.attributes.inspect}, right:#{right_elm.attributes.inspect}" unless equal_attributes?(left_elm, right_elm)
    left_children = left_elm.children
    right_children = right_elm.children
    raise "Children size unmatch: left:#{left_children.size}, right:#{right_children.size}" unless left_children.size == right_children.size
    left_children.each_with_index do |left_child, index|
      right_child = right_children[index]
      compare_element(left_child, right_child)
    end
    true
  end
  def equal_attributes?(left, right)
    return false unless left.keys.sort == right.keys.sort
    left.keys.each do |k|
      return false unless left[k] == right[k]
    end
    true
  end
end
