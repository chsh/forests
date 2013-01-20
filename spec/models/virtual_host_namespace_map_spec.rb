require "spec_helper"

describe VirtualHostNamespaceMap do
  before(:each) do
    @user = create :inactive_user
    cc = MongoConnection.class_config['default']
    @mc = MongoConnection.create :name => cc['name'],
                             :host => cc['host'],
                             :port => cc['port'],
                             :db => cc['db']
    cc = MongoConnection.class_config['default_gridfs']
    @mc_gfs = MongoConnection.create :name => cc['name'],
                             :host => cc['host'],
                             :port => cc['port'],
                             :db => cc['db']
    cc = SolrConnection.class_config['default']
    @sc = SolrConnection.create :name => cc['name'],
                                :url => cc['url'],
                                :options => cc['options']
  end
=begin
  it "should should update site vitualhost map" do
    @user.sites.create :name => 'test1', :virtualhost => 'x.lo'
    vnm = VirtualHostNamespaceMap.new(:update_interval => 1).update
    vnm['x.lo'].should == 'test1'
    vnm['y.lo'].should be_nil
    @user.sites.create :name => 'test2', :virtualhost => 'y.lo'
    vnm['y.lo'].should be_nil
    sleep 1
    vnm['y.lo'].should == 'test2'
  end
=end
  it 'should detect timeout using Timer.' do
    t1 = VirtualHostNamespaceMap::Timer.new(1)
    t1.over?.should == false
    sleep 1
    t1.over?.should == true
    t2 = VirtualHostNamespaceMap::Timer.new(1)
    sleep 1
    val = nil
    t2.if_over do
      val = 100
    end
    val.should == 100
  end
  after(:each) do
    @user.destroy
    @mc.destroy
    @mc_gfs.destroy
    @sc.destroy
  end
end
