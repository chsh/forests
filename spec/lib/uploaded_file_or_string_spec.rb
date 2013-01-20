require "spec_helper"

require 'tempfile'
class LocalUploadedFile
  # The filename, *not* including the path, of the "uploaded" file
  attr_reader :original_filename
  # The content type of the "uploaded" file
  attr_reader :content_type
  def initialize(path, content_type = 'text/plain')
    raise "#{path} file does not exist" unless File.exist?(path)
    @content_type = content_type
    @original_filename = path.sub(/^.*#{File::SEPARATOR}([^#{File::SEPARATOR}]+)$/) { $1 }
    @tempfile = Tempfile.new(@original_filename)
    FileUtils.copy_file(path, @tempfile.path)
  end
  def path #:nodoc:
    @tempfile.path
  end
  alias local_path path
  def method_missing(method_name, *args, &block) #:nodoc:
    @tempfile.send(method_name, *args, &block)
  end
end

describe UploadedFileOrString do

  it "should treat file string/uploaded file" do
    ufos1 = UploadedFileOrString.new 'spec/files/uploaded_file_or_string/test.data'
    ufos1.extname.should == '.data'
    ufos1.basename.should == 'test.data'
    ufos1.basename('.*').should == 'test'

    ufos2 = UploadedFileOrString.new LocalUploadedFile.new('spec/files/uploaded_file_or_string/test.data')
    ufos2.extname.should == '.data'
    ufos2.basename.should == 'test.data'
    ufos2.basename('.*').should == 'test'

    ufos3 = UploadedFileOrString.new 'spec/files/uploaded_file_or_string/test.data'
    (ufos3.read(10) == File.read('spec/files/uploaded_file_or_string/test.data', 10)).should == true
    ufos4 = UploadedFileOrString.new 'spec/files/uploaded_file_or_string/test.data'
    (ufos4.read == File.read('spec/files/uploaded_file_or_string/test.data')).should == true
  end

  it 'should copy file content from other.' do
    mfs = MongoFiles.new('copy-content-holder')
    mfs.save('image/test.png', File.open('spec/files/uploaded_file_or_string/file1.png', 'rb').read)
    mf = MongoFile.new(mfs, 'image/test.png')
    ufos = UploadedFileOrString.new mf
    ufos.extname.should == '.png'
    (ufos.read == File.open('spec/files/uploaded_file_or_string/file1.png', 'rb').read).should == true
  end

end
