# encoding: UTF-8
require 'spec_helper'

describe FormExtractor do
  before(:each) do
  end

  it 'should render proper content' do
    content = '<div style="font-size: small">あれま!</div>'
    ex = FormExtractor.from(content)
    ex.render(nil).should == content
  end
end
