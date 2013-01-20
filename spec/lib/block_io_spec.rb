# encoding: UTF-8
require 'spec_helper'

describe BlockIO, "BlockIos" do
  it 'must copy from to.' do
    from = StringIO.new('abcdefg')
    to = StringIO.new
    BlockIO.copy(from, to)
    to.string.should == 'abcdefg'
  end

  it 'must copy by block' do
    from = StringIO.new('abcdefg')
    to = StringIO.new
    BlockIO.copy(from, to, 1)
    to.string.should == 'abcdefg'
    from = StringIO.new('abcdefg')
    to = StringIO.new
    BlockIO.copy(from, to, 7)
    to.string.should == 'abcdefg'
  end

  it 'must copy japanese text' do
    from = StringIO.new('いろはにほへとちりぬるを')
    to = StringIO.new
    BlockIO.copy(from, to, 1)
    to.string.should == 'いろはにほへとちりぬるを'
  end

  it 'must copy large content.' do
    from = File.new('spec/files/block_io/large.file')
    to = StringIO.new
    BlockIO.copy(from, to)
    to.string.size == File.size('spec/files/block_io/large.file')
  end
end
