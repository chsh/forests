require "spec_helper"

describe KeyIdentifier do

  it "should make key identifier from one_table and header index" do
    KeyIdentifier.header_key(5).should == 'h5'
    KeyIdentifier.header_key('a').should == 'ha'
  end
  it "should restore header index from key." do
    KeyIdentifier.header_index('h3').should == 3
    KeyIdentifier.header_index('99899').should be_nil
    KeyIdentifier.header_index('ha').should be_nil
  end
  it "should extract ids from key" do
    KeyIdentifier.extract_id('h98').should == 98
    KeyIdentifier.extract_id('99899').should be_nil
    KeyIdentifier.extract_id('H98').should be_nil
    KeyIdentifier.extract_id('oth').should be_nil
    KeyIdentifier.extract_id('ot3h').should be_nil
    KeyIdentifier.extract_id('o32h8').should be_nil
    KeyIdentifier.extract_id('OT32h8').should be_nil
  end
  it "can compare 2 keys" do
    KeyIdentifier.compare('h3', 'h2').should > 0
    KeyIdentifier.compare('h4', 'h4').should == 0
    KeyIdentifier.compare('h56', 'h300').should < 0
    lambda { KeyIdentifier.compare('56', 'h300') }.should raise_error
  end
  it "can combine ids" do
    KeyIdentifier.combine_ids(1, 2).should == 'ot1h2'
    otn = create :one_table, id: 543
    KeyIdentifier.combine_ids(otn, 10).should == 'ot543h10'
    otr = OneTableRecord.new
    otr.id = 41
    KeyIdentifier.combine_ids("ot5", otr).should == 'ot5h41'
    lambda { KeyIdentifier.combine_ids(nil, nil) }.should raise_error
  end
  it 'has #solrize_hash' do
    h = { 'a' => 1, 'b' => 2 }
    h2 = KeyIdentifier.append_solr_keys(h, 'ck', 1234)
    h2.should == {
            'dom_ks' => 'ck', 'dom_ki' => 1234,
            'id' => 'ck_1234',
            'a' => 1, 'b' => 2 }
  end

  it 'has #one_table_key' do
    KeyIdentifier.one_table_key(100).should == 'ot100'
  end

  it 'has #solr_collection_query' do
    KeyIdentifier.solr_collection_query(100).should == 'dom_ks:ot100'
  end
end
