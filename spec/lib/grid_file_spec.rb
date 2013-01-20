require "spec_helper"

require 'mongo'

describe "GridFile" do
  before(:each) do
    cc = MongoConnection.class_config['default_gridfs']
    @mcon = Mongo::Connection.new(cc['host'], cc['port'].to_i)
    @dbname = cc['db']
    @db = @mcon.db @dbname
  end
  it "should manipulate GridFS" do
    gf = GridFile.new @db, 'test'
    gf.exist?('testfile.data').should == false
    gf.open('test001.dat', 'w') do |g|
      g.write 'abcdefg'
    end
    gf.exist?('test001.dat').should == true
    gf.read('test001.dat').should == 'abcdefg'
    writer = StringIO.new
    gf.read('test001.dat', writer)
    writer.string.should == 'abcdefg'

    gf.destroy
    gf.exist?('test001.dat').should == false

    gf2 = GridFile.new @db
    cont = 'abcdefg' * 1000 * 1000
    gf2.open('test001.dat', 'w') do |g|
      g.write cont
    end
    cont_r = gf2.read('test001.dat')
    (cont_r == cont).should == true
    gf2.list.sort.should == ['test001.dat']

  end
  after(:each) do
    @mcon.drop_database @dbname
  end
end
