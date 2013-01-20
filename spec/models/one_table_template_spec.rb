# -*- coding: utf-8 -*-

require 'spec_helper'

describe OneTableTemplate do
  before(:each) do
    OneTable.destroy_all
    User.destroy_all
  end

  it 'should select export fields' do
    ot = create :one_table
    ot.send(:mcol).drop
    headers = [['マーカー種別', :string], ['利用日付', :time], ['合計', :integer], ['備考', :text]]
    rows = [
            ['abc', Time.parse('2009/9/30'), 123, 'これは備考です。abcを含みます。'],
            ['いろは', nil, 456, 'これは一つのペンです。'],
            ['xyz', Time.parse('2010/3/21'), 0, 'これは別の例です。'],
            ['ABC', Time.parse('2001/5/10'), -2500, 'これは大文字の例です。ABCが入っています。'],
           ]
    ot.headers = headers
    ot.rows = rows
    ot.one_table_templates << FactoryGirl.build(:one_table_template)
    ott = ot.one_table_templates.first
    ott.one_table_template_one_table_headers <<
        OneTableTemplateOneTableHeader.new(
            one_table_header_id: ot.one_table_headers[0].id,
            index: 1
        )
    ott.one_table_template_one_table_headers <<
        OneTableTemplateOneTableHeader.new(
            one_table_header_id: ot.one_table_headers[2].id,
            index: 0
        )
    c = ott.content_for
    c.force_encoding 'BINARY'
    r = File.open('spec/files/one_table_template/test1.csv', 'rb').read.gsub(/\r?\n/, "\r\n")
    c.should == r
  end
end
