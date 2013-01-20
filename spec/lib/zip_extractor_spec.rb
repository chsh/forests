# encoding: UTF-8
require "spec_helper"

describe ZipExtractor do

  it 'should check acceptable file or not.' do
    ZipExtractor.acceptable?("#{Rails.root}/spec/files/zip_extractor/project.zip").should be_true
    ZipExtractor.acceptable?("#{Rails.root}/spec/files/zip_extractor/extracted/boost-build.jam").should_not be_true
  end
  it "should extract files in zip" do
#    extract_to = "#{Rails.root}/spec/files/zip_extractor/temp1"
#    FileUtils.rm_r(extract_to)
#    FileUtils.mkdir(extract_to)
#    ze = ZipExtractor.from("#{Rails.root}/spec/files/zip_extractor/project.zip")
    ze1 = ZipFileExtractor.new("#{Rails.root}/spec/files/zip_extractor/project.zip", :shallow_path => false)
    files = []
    ze1.each_entry do |entry|
      files << entry.name
    end
    files.should == %w(project/boost-build.jam project/Jamfile project/Jamrules)
    ze2 = ZipFileExtractor.new("#{Rails.root}/spec/files/zip_extractor/project.zip")
    files = []
    ze2.each_entry do |entry|
      files << entry.name
    end
    files.should == %w(boost-build.jam Jamfile Jamrules)
    jam_processed = false
    ze2.each_entry do |entry|
      if entry.name == 'boost-build.jam'
        entry.read.should == File.open("#{Rails.root}/spec/files/zip_extractor/extracted/boost-build.jam", 'rb').read
        jam_processed = true
      end
    end
    jam_processed.should be_true
  end

  it 'should treat NFDed string correctly.' do
    ze1 = ZipFileExtractor.new("#{Rails.root}/spec/files/zip_extractor/unf-check.zip", :shallow_path => true)
    files = []
    ze1.each_entry do |entry|
      files << entry.name
    end
    # 学科コー「ド」 should be regulated to single char.
    files.should == %w(course-_学科コード_.html)
  end

  it 'should handle object which has :path method.' do
    @tf = Tempfile.new('basename', encoding: 'BINARY')
    src_file = "#{Rails.root}/spec/files/zip_extractor/project.zip"
    @tf.write(File.open(src_file, 'rb').read)
    @tf.close
    ze = ZipExtractor.from(@tf, shallow_path: false)
    files = []
    ze.each_entry do |entry|
      files << entry.name
    end
    files.should == %w(project/boost-build.jam project/Jamfile project/Jamrules)

  end

  after(:each) do
    if @tf && @tf.is_a?(Tempfile)
      @tf.close(true)
    end
  end
end
