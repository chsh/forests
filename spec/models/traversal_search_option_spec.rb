require 'spec_helper'

describe TraversalSearchOption do
  before(:each) do
    @user = create :user
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
    cc = MongoConnection.class_config['media_keeper']
    @mc_mk = MongoConnection.create :name => cc['name'],
                             :host => cc['host'],
                             :port => cc['port'],
                             :db => cc['db']
    cc = SolrConnection.class_config['default']
    @sc = SolrConnection.create :name => cc['name'],
                                :url => cc['url'],
                                :options => cc['options']
  end
  after(:each) do
    @mc.destroy
    @mc_gfs.destroy
    @mc_mk.destroy
    @sc.destroy
    @user.destroy
  end
  it "should be deleted by one_table deletion." do
    ot = @user.one_tables.create :name => 'test1'
    ot.traversal_search_option.should be_nil
    tso = ot.create_traversal_search_option
    ot.destroy
    TraversalSearchOption.find_by_id(tso.id).should be_nil
  end

  it 'should be created with valid options' do
    lambda {
      TraversalSearchOption.create
    }.should raise_error
    tso = TraversalSearchOption.create one_table_id: 1,
                                       fields_map: {
                                           department: 0,
                                           course: 1,
                                           title: 2,
                                           desc: 3,
                                       },
                                       url_format: {
                                           pattern: 'http://syl-web1.code.ouj.ac.jp/sample/id-[4].html'
                                       }
    tso1 = TraversalSearchOption.find(tso)
    tso1.fields_map.should == {
        department: 0,
        course: 1,
        title: 2,
        desc: 3
    }
    tso1.url_format.should == {
        pattern: 'http://syl-web1.code.ouj.ac.jp/sample/id-[4].html'
    }
    tso1.options.should == {
        fields_map: {
            department: 0,
            course: 1,
            title: 2,
            desc: 3,
        },
        url_format: {
            pattern: 'http://syl-web1.code.ouj.ac.jp/sample/id-[4].html'
        }
    }
  end
end
