# -*- encoding: UTF-8 -*-

require 'spec_helper'

describe PersonalHelper do

  it 'should calculate charwidth as fixed width font size.' do
    charwidth("abc").should == 3
    charwidth("いろc").should == 5
    lambda {
      charwidth nil
    }.should raise_error
    hf_width('あ').should == 2
    hf_width('a').should == 1
    charwidth_chop('いろは', 5).should == 'いろ…'
    charwidth_chop(nil, 10).should be_nil
    dt = Date.today
    charwidth_chop(dt, 5).should == dt
    tm = Time.now
    charwidth_chop(tm, 5).should == tm
  end
  it 'should chop string using :strlen_widtin value.' do
    view_by_type('いろは').should == 'いろは'
    view_by_type('いろは', strlen_within: 5).should == 'いろ…'
    view_by_type('abcい', strlen_within: 10).should == 'abcい'
  end
  it 'should calculate em width by data size.' do
    ems_by([['いろは', 'x']]).should == [6, 1]
    ems_by([['いろは', 'x']], num_fields: 4).should == [6, 1, 0, 0]
  end
end
