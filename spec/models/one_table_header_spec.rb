# encoding: UTF-8
require "spec_helper"

describe OneTableHeader do

  it "provide solr_key" do
    oth = OneTableHeader.new :sysname => 'hello', :kind => 1, :label => 'こんにちは'
                             #, :multiple => false
    oth.solr_key.should == 'hello_s'
    oth.kind = 2
    oth.solr_key.should == 'hello_t'
    oth.kind = 3
    oth.solr_key.should == 'hello_d'
    oth.kind = 4
    oth.solr_key.should == 'hello_i'
    oth.multiple = true
    oth.kind = 1
    oth.solr_key.should == 'hello_sm'
    oth.kind = 2
    oth.solr_key.should == 'hello_tm'
    oth.kind = 3
    oth.solr_key.should == 'hello_dm'
    oth.kind = 4
    oth.solr_key.should == 'hello_im'
  end

  it 'can convert type by kind' do
    oth = OneTableHeader.new :sysname => 'hello' # default: :multiple => false
    oth.kind = 1
    oth.solr_value('a').should == 'a'
    oth.kind = 2
    oth.solr_value('b').should == 'b'
    oth.kind = 3
    oth.solr_value(Date.parse('2010/1/10')).class.should == Time
    oth.kind = 4
    oth.solr_value('c').should == 'c'
    oth.multiple = true
    oth.kind = 1
    oth.solr_value('a').should == ['a']
    oth.kind = 2
    oth.solr_value('b').should == ['b']
    oth.kind = 3
    oth.solr_value(Date.parse('2010/1/10'), Date.parse('2010/1/11')).map { |d| d.class }.should == [Time, Time]
    oth.kind = 4
    oth.solr_value('c', 'd').should == ['c', 'd']
  end

  it 'provide solr_key_and_value' do
    oth = OneTableHeader.new :sysname => 'hello' # default: :multiple => false
    oth.kind = 1
    oth.solr_key_and_value_pairs('a').should == ['hello_s', 'a']
    oth.kind = 2
    oth.solr_key_and_value_pairs('b').should == ['hello_t', 'b']
    oth.kind = 3
    oth.solr_key_and_value_pairs(Date.parse('2010/1/10').to_time.utc).should == [
            'hello_d', '2010-01-09T15:00:00Z',
            'hello_wday_i', 0,
            'hello_year_i', 2010,
            'hello_month_i', 1,
            'hello_day_i', 10
    ]
    oth.kind = 4

    oth.multiple = true
    oth.solr_key_and_value_pairs(100).should == ['hello_im', [100]]
    oth.kind = 1
    oth.solr_key_and_value_pairs('a', 'b', 'c').should == ['hello_sm', ['a', 'b', 'c']]
    oth.kind = 2
    oth.solr_key_and_value_pairs('b').should == ['hello_tm', ['b']]
    oth.kind = 3
    oth.solr_key_and_value_pairs(['2010/1/10', '2011/3/21'].map { |ds| Date.parse(ds).to_time.utc }).should == [
            'hello_dm', [Time.parse('2010/1/10'), Time.parse('2011/3/21')],
            'hello_wday_im', [0, 1],
            'hello_year_im', [2010, 2011],
            'hello_month_im', [1, 3],
            'hello_day_im', [10, 21]
    ]
    oth.kind = 4
    oth.solr_key_and_value_pairs(100).should == ['hello_im', [100]]
  end

  it 'has #key_and_value' do
    oth = OneTableHeader.new :sysname => 'hello' # default: :multiple => false
    oth.kind = 1
    oth.key_and_value('a').should == ['hello', 'a']
    oth.kind = 2
    oth.key_and_value('b').should == ['hello', 'b']
    oth.kind = 3
    oth.key_and_value(Date.parse('2010/1/10')).should == ['hello', Time.parse('2010/1/10')]
    oth.kind = 4

    oth.multiple = true
    oth.key_and_value(100, 200).should == ['hello', [100, 200]]
    oth.kind = 1
    oth.key_and_value(['a', 'b']).should == ['hello', ['a', 'b']]
    oth.kind = 2
    oth.key_and_value('b').should == ['hello', ['b']]
    oth.kind = 3
    oth.key_and_value(Date.parse('2010/1/10'),
                      Date.parse('2010/3/21')).should == ['hello', [Time.parse('2010/1/10'),
                                                                    Time.parse('2010/3/21')]]
    oth.kind = 4
    oth.key_and_value(100, 200, 300).should == ['hello', [100, 200, 300]]
  end

  it 'can save/load instance value.' do
    User.delete_all
    u = create :user
    ot = OneTable.create :name => 'ot1', :user_id => u.id
    oth = ot.one_table_headers.create :sysname => 'hello', :kind => 1,
                                      :label => 'こんにちは', :refname => 'hello-ref',
                                      :comment => {:misc => '備考です。'}, :multiple => true
    oth2 = OneTableHeader.find oth.id
    oth2.sysname.should == 'hello'
    oth2.kind.should == 1
    oth2.label.should == 'こんにちは'
    oth2.refname.should == 'hello-ref'
    oth2.comment.should == {:misc => '備考です。'}
    oth2.multiple?.should == true
    mcid = oth2.model_comment.id
    oth2.destroy
    ModelComment.find_by_id(mcid).should be_nil
  end

end
