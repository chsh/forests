# encoding: UTF-8
require 'spec_helper'

describe TableReader do

  it 'can get selected row as hash.' do
    tr = TableReader.new([:a, :b, :c], [
            %w(い ろ は), %w(x y z)])
#    tr.at(0).should == ['い', 'ろ', 'は']
    tr.at(0).should == %w(い ろ は)
    tr.at_hash(1).should == {:a => 'x', :b => 'y', :c => 'z'}
  end

  it 'can get selected columns distinctlly.' do
    tr = TableReader.new(%w(主 副 タイトル), [
            %w(ア い A),
            %w(ア い B),
            %w(ア ろ C),
            %w(ア ろ D),
            %w(ア ろ E),
            %w(ア は A),
            %w(ア は C),
            %w(ア は E),
            %w(ア は F),
            %w(イ に A),
            %w(イ に B),
            %w(イ い A),
            %w(イ い B),
            %w(イ ほ G)
    ])
    tr.select_rows({'主' => 'ア'}).should == [
            %w(ア い A),
            %w(ア い B),
            %w(ア ろ C),
            %w(ア ろ D),
            %w(ア ろ E),
            %w(ア は A),
            %w(ア は C),
            %w(ア は E),
            %w(ア は F),
    ]
    tr.distinct_values('主').should == %w(ア イ)
    tr.distinct_values('副', {'主' => 'ア'}).should == %w(い ろ は)
    tr.count.should == 14
  end

  it 'can select squeeze rows by conditions' do
    tr = TableReader.new(%w(主 副 タイトル), [
            %w(ア い A),
            %w(ア い B),
            %w(ア ろ C),
            %w(ア ろ D),
            %w(ア ろ E),
            %w(ア は A),
            %w(ア は C),
            %w(ア は E),
            %w(ア は F),
            %w(イ に A),
            %w(イ に B),
            %w(イ い A),
            %w(イ い B),
            %w(イ ほ G)
    ])
    tr2 = tr.squeeze({'主' => 'ア'})
    tr2.headers.should == %w(主 副 タイトル)
    tr2.rows.should == [
            %w(ア い A),
            %w(ア い B),
            %w(ア ろ C),
            %w(ア ろ D),
            %w(ア ろ E),
            %w(ア は A),
            %w(ア は C),
            %w(ア は E),
            %w(ア は F),
    ]
  end

  it "can create instance from hash array." do
    tr = TableReader.from_hash_array([
            { 'a' => 1, 'b' => 2, 'c' => 3},
            { 'b' => 'y', 'a' => 'x', 'c' => 'z'},
            { 'c' => 'は', 'a' => 'い', 'b' => 'ろ'},
    ])
    tr.headers.should == %w(a b c)
    tr.rows.should == [
            [1, 2, 3],
            ['x', 'y', 'z'],
            ['い', 'ろ', 'は']
    ]
    lambda {
      TableReader.from_hash_array([
              { 'a' => 1, 'b' => 2, 'c' => 3},
              { 'a' => 'y', 'b' => 'x', 'd' => 'z'},
      ])
    }.should raise_error
    lambda {
      TableReader.from_hash_array([
              { 'a' => 1, 'b' => 2, 'c' => 3},
              { 'a' => 'y', 'b' => 'x', 'c' => 'z', 'd' => 1234},
              { 'b' => 'z'},
      ])
    }.should_not raise_error
    lambda {
      TableReader.from_hash_array([
              { 'b' => 'z'},
              { 'a' => 'y', 'b' => 'x', 'c' => 'z', 'd' => 1234},
              { 'a' => 1, 'b' => 2, 'c' => 3},
      ])
    }.should_not raise_error
  end

  it 'should sort specific column(s)' do
    tr = TableReader.new(%w(主 副 タイトル), [
            %w(ア は C),
            %w(イ に B),
            %w(ア は E),
            %w(ア い A),
            %w(ア い B),
            %w(イ ほ G),
            %w(ア ろ D),
            %w(ア は F),
            %w(イ に A),
    ])
    tr2 = tr.sort('主 desc', 'タイトル asc')
    tr2.rows.should == [
            %w(イ に A),
            %w(イ に B),
            %w(イ ほ G),
            %w(ア い A),
            %w(ア い B),
            %w(ア は C),
            %w(ア ろ D),
            %w(ア は E),
            %w(ア は F),
    ]
    tr2.rows.should == tr.sort('主 desc, タイトル asc').rows
    lambda {
      tr.sort('主 posc')
    }.should raise_error
    lambda {
      tr.sort('なし asc')
    }.should raise_error

    tr3 = TableReader.new(%w(主 副 タイトル), [
            [nil, 'は', 'C'],
            ['ロ', 'X', '123'],
            ['イ', 'に', 'B'],
    ])
    tr3.sort('主 asc').rows.should == [
            ['イ', 'に', 'B'],
            ['ロ', 'X', '123'],
    ]

  end
end
