# encoding: UTF-8
require 'spec_helper'

describe Formula::Join do

  it 'should combine some fields.' do
    fj = Formula::Join.new
    fj.params = {
            :fields => ['h3', 'h2', 'h0'],
            :delimiter => '/'
    }
    row = {
            'h0' => 'first cell',
            'h1' => 'second cell',
            'h2' => '三番目',
            'h3' => 'last cell'
    }
    fj.eval(row).should == 'last cell/三番目/first cell'
  end
end
