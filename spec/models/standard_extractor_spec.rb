# encoding: UTF-8
require 'spec_helper'

describe StandardExtractor do
  before(:each) do
  end

  it "should render content" do
    src_content = '<div><a href="_リンクターゲット_.html">_リンク名_</a></div>'
    ex = StandardExtractor.from(src_content, 'text/html')
    ex.render(nil).should == src_content
    ex.render({
            'リンクターゲット' => '自分 (単位)',
            'リンク名' => 'リンク名称'
    }).should == '<div><a href="自分 (単位).html">リンク名称</a></div>'
  end
end
