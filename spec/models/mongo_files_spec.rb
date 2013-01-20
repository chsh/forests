require "spec_helper"

describe "MongoFiles" do
  before(:each) do
    @mc = MongoConnection.create :name => 'site_filesystem',
                           :host => 'localhost',
                           :port => '27017',
                           :db => 'one-table-site-fs-test'
    db = MongoConnection.site_filesystem.remote_connection
    con = db.connection
    con.drop_database @mc.db
  end
  after(:each) do
    @mc.destroy
  end

  it "should be available to save/load content with filename" do
    moncon = MongoConnection.site_filesystem.remote_connection
    mf = MongoFiles.new('test001')
    filename = "spec/files/mongo_files/rails.png"
    File.open(filename, 'r') do |f|
      mf.save filename, f
    end
    content_type = nil
    content = nil
    Mongo::GridFileSystem.new(moncon, 'test001').open(filename, 'r') do |gs|
      content_type = gs.content_type
      content = gs.read
    end
    fc = File.open(filename, 'rb').read
    (content == fc).should ==  true
    content_type.should == 'image/png'
    mf.list_names.include?(filename).should == true
    mf.delete filename
    mf.list_names.include?(filename).should == false
  end

  it "can copy other MongoFiles's content." do
    mf = MongoFiles.new('test002')
    mf.list_names.should == []
    filename1 = "spec/files/mongo_files/rails.png"
    File.open(filename1, 'r') do |f|
      mf.save filename1, f
    end
    filename2 = "spec/files/mongo_files/rakefile.txt"
    File.open(filename2, 'r') do |f|
      mf.save filename2, f.read
    end
    mf.list_names.sort.should == %w(spec/files/mongo_files/rails.png
                                   spec/files/mongo_files/rakefile.txt)
    mf2 = MongoFiles.new('test002a')
    mf2.import mf
    mf2.list_names.sort.should == %w(spec/files/mongo_files/rails.png
                                   spec/files/mongo_files/rakefile.txt)
  end

  it 'can destroy itself.' do
    mf = MongoFiles.new('test003-di')
    mf.list_names.should == []
    mf.add 'spec/files/mongo_files/rails.png'
    mf.list_names.should == %w(spec/files/mongo_files/rails.png)
    mf.destroy
    mf.list_names.should == []
  end

  it 'can save additional files.' do
    mf = MongoFiles.new('test004-saf')
#    mf.list_names.should == []
    mf.add 'spec/files/mongo_files/rails.png'
    mf.add 'spec/files/mongo_files/rakefile.txt'
    mf.list_names.sort.should == %w(spec/files/mongo_files/rails.png
                                   spec/files/mongo_files/rakefile.txt)
    mf.destroy
    mf.list_names.should == []
    mf.add 'spec/files/mongo_files/rails.png', 'spec/files/mongo_files/rakefile.txt'
    mf.list_names.sort.should == %w(spec/files/mongo_files/rails.png
                                   spec/files/mongo_files/rakefile.txt)
    mf.destroy
    mf.list_names.should == []
    mf.add %w(spec/files/mongo_files/rails.png spec/files/mongo_files/rakefile.txt)
    mf.list_names.sort.should == %w(spec/files/mongo_files/rails.png
                                   spec/files/mongo_files/rakefile.txt)
    mf.destroy
  end

  it 'should import valid file type only.' do
    mfi = MongoFiles.new('test002a')
    lambda {
      mfi.import "spec/files/mongo_files/rails.png"
    }.should raise_error
    lambda {
      mfi.import "not/existent/file"
    }.should raise_error
  end
end
