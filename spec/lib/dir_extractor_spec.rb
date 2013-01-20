require "spec_helper"

describe DirExtractor do

  it "should extract files in directory" do
    lambda {
      DirExtractor.new("#{Rails.root}/spec/files/dir_extractor/not-existent-folder")
    }.should raise_error
    de = DirExtractor.new("#{Rails.root}/spec/files/dir_extractor/folder1")
    files = []
    de.each_entry do |f|
      files << f.name
    end
    files.should == ['README', 'Rakefile', 'rails.png']
  end
end
