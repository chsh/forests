# encoding: UTF-8
require "spec_helper"

describe Formula::ConvertJoin do

  it "should should combine some fields with conversion" do
    # :script accepts string or file
    fj1 = Formula::ConvertJoin.new
    fj1.params = {
            :fields => ['h3', 'h2', 'h0'],
            :delimiter => '/',
            :script => 'value * 2'
    }
    row1 = {
            'h0' => 'first cell',
            'h1' => 'second cell',
            'h2' => '三番目',
            'h3' => 'last cell'
    }
    fj1.eval(row1).should == 'last celllast cell/三番目三番目/first cellfirst cell'

    fj2 = Formula::ConvertJoin.new
    fj2.params = {
            :fields => ['h3', 'h2', 'h0'],
            :delimiter => '/',
            :script => 'spec/files/formula/convert_join/script1.rb'
    }
    row2 = {
            'h0' => 'first cell',
            'h1' => 'second cell',
            'h2' => '三番目',
            'h3' => 'last cell'
    }
    lambda {
      fj2.eval(row2)
    }.should raise_error
    # now :script by file is not acceptable.

    fj3 = Formula::ConvertJoin.new
    fj3.params = {
            :fields => ['h3', 'h2', 'h0'],
            :delimiter => '/',
            :script => File.read('spec/files/formula/convert_join/script1.rb')
    }
    row3 = {
            'h0' => 'first cell',
            'h1' => 'second cell',
            'h2' => '三番目',
            'h3' => 'last cell'
    }
    fj3.eval(row3).should == 'last cell/何/first cell'

  end
  it "should cause error by wrong script." do
    fj3 = Formula::ConvertJoin.new
    fj3.params = {
            :fields => ['h3', 'h2', 'h0'],
            :delimiter => '/',
            :script => 'valuex + 33'
    }
    row3 = {
            'h0' => 'first cell',
            'h1' => 'second cell',
            'h2' => '三番目',
            'h3' => 'last cell'
    }
    lambda {
      fj3.eval(row3)
    }.should raise_error
  end

  it 'should join using :join_script value.' do
    fjj = Formula::ConvertJoin.new
    fjj.params = {
            :fields => ['h3', 'h2', 'h0'],
            :delimiter => '/',
            :script => 'value.gsub(/cell/, "CELL")',
            :join_script => 'values.sort.join(":")'
    }
    rowj = {
            'h0' => 'first cell',
            'h1' => 'second cell',
            'h2' => '三番目',
            'h3' => 'last cell'
    }
    fjj.eval(rowj).should == 'first CELL:last CELL:三番目'
  end
end
