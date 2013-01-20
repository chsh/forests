# encoding: UTF-8
require 'spec_helper'

describe PageBlockBuilder do
  before do
  end

  it 'can join block_refs and blocks' do
    content = File.read("#{Rails.root}/spec/files/page_block_builder/content1.html")
    pbb = PageBlockBuilder.new(content)
    # result includes joined content and ot-comments.
    pbb.to_page_content.should == File.read("#{Rails.root}/spec/files/page_block_builder/content1.result.html")
  end

  it 'should extract html content to block_refs and blocks' do
    content = File.read("#{Rails.root}/spec/files/page_block_builder/content2.html")
    pbb = PageBlockBuilder.new(content)
    block_ref, blocks = pbb.parse
    block_ref.gsub(/\t/, '').should == File.read("#{Rails.root}/spec/files/page_block_builder/content2.block_ref.html").gsub(/\t/, '')
    blocks.should == {
            "ot1" => "<li style=\"width: 150px; height: 30px\">\n    <span>_hello_</span>\n</li>"
    }
    br2, b2 = PageBlockBuilder.parse(content)
    br2.gsub(/\t/, '').should == File.read("#{Rails.root}/spec/files/page_block_builder/content2.block_ref.html").gsub(/\t/, '')
    b2.should == {
            "ot1" => "<li style=\"width: 150px; height: 30px\">\n    <span>_hello_</span>\n</li>"
    }
  end

  it 'can treat utf8 text correctly.' do
    content = '<tag ot="t1"><span>テスト</span></tag>'
    pbb = PageBlockBuilder.new(content)
    _, blocks = pbb.parse
    blocks.size.should == 1
    # result includes joined content and ot-comments.
    blocks.should == {
      "t1"=>"<tag>\n    <span>テスト</span>\n</tag>"
    }
  end

  it 'can merget blocks into content.' do
    content = File.read("#{Rails.root}/spec/files/page_block_builder/content3.html")
    result_content = File.read("#{Rails.root}/spec/files/page_block_builder/content3.result.html")
    blocks = {
      "t1"=>'<tag id="tagid55"><span style="width: 300px">テストその2</span><span style="height: 100px">テストXです</span></tag>'
    }
    PageBlockBuilder.merge(content, blocks).should == result_content
  end

  it 'should not do encode url.' do
    content = '<tag ot="t1"><a href="テスト.html">てすと</a> <a href="_テスト_.html">test</a></tag>'
    pbb = PageBlockBuilder.new(content)
    _, blocks = pbb.parse
    blocks.size.should == 1
    # result includes joined content and ot-comments.
    blocks.should == {
      "t1"=>"<tag><a href=\"テスト.html\">てすと</a> <a href=\"_テスト_.html\">test</a></tag>"
    }
  end
end
