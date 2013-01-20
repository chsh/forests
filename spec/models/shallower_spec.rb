require 'spec_helper'

describe Shallower do
  before(:each) do
  end

  it 'can shallow path.' do
    paths =
    sp = Shallower.new
    sp.shallow([
            'a/b/c.html',
            'a/b/d.txt'
    ]).should == [
            'c.html', 'd.txt'
    ]
    sp.shallow([
            'a/b/c/d/e.html',
            'a/b/c/d.html',
            'a/b.html'
    ]).should == [
            'b/c/d/e.html',
            'b/c/d.html',
            'b.html'
    ]
    sp.shallow([
            'a/b/c/d/e.html',
            'a/b/c/d/ef.html',
            'a/b/c/d/g.html'
    ]).should == [
            'e.html',
            'ef.html',
            'g.html'
    ]
  end
end
