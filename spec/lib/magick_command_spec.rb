require "spec_helper"

describe MagickCommand do

  it "should get size attribute from file or content." do
    size1a = MagickCommand.size('spec/files/magick_command/test1.png')
    size1a.should == { :width => 720, :height => 400 }
    size1b = MagickCommand.size('spec/files/magick_command/test1.png', :result => :string)
    size1b.should == '720x400'
    size2 = MagickCommand.size(File.open('spec/files/magick_command/test2.gif').read)
    size2.should == { :width => 157, :height => 53 }
    lambda {
      MagickCommand.size('not-existent-file.name')
    }.should raise_error
  end

end
