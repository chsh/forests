# encoding: UTF-8
require "spec_helper"

describe BlockContentRenderer do

  it "should should render correct data view" do
    bcr = BlockContentRenderer.new "_test1_ / _test2_", 'text/plain'
    bcr.render.should == '_test1_ / _test2_'
    bcr.render({'test1' => Time.parse('2010/1/31 14:00:32')}).should == '2010年1月31日(日) / '
    bcr.render({'test1' => 'ほげ', 'test2' => 'me'}).should == 'ほげ / me'
    h = {
        :value => 't001.jpg',
        :metadata => {
            :width => 25,
            :height => 120,
            :id => 223
        }
    }
    bcr.render({'test1' => h, 'test2' => 'You'}).should == '<img src="/files/223/t001.jpg"/> / You'
  end
end
