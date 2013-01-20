require "spec_helper"

describe BlockSearchItemsExtractor do

  it "should split cmd and opts" do
    bsie = BlockSearchItemsExtractor.new nil
    cmd1, opts1 = bsie.send :split_cmd_and_opts, nil
    cmd1.should be_nil
    opts1.should == {}

    cmd2, opts2 = bsie.send :split_cmd_and_opts, ":"
    cmd2.should == nil
    opts2.should == {}

    cmd3, opts3 = bsie.send :split_cmd_and_opts, "cmd_a:b:c:d"
    cmd3.should == 'cmd_a'
    opts3.should == {
            :b => true, :c => true, :d => true
    }
  end
end
