# encoding: UTF-8
require 'spec_helper'

describe Site do
  before(:each) do
    @user = create :user, :email => 'info1@example.com'
    @user2 = create :user, :email => 'info2@example.com'
    cc = MongoConnection.class_config['default']
    @user.one_tables.destroy_all
    @user.sites.destroy_all
    @user2.one_tables.destroy_all
    @user2.sites.destroy_all
    @mc = MongoConnection.create :name => cc['name'],
                             :host => cc['host'],
                             :port => cc['port'],
                             :db => cc['db']
    cc = MongoConnection.class_config['default_gridfs']
    @mc_gfs = MongoConnection.create :name => cc['name'],
                             :host => cc['host'],
                             :port => cc['port'],
                             :db => cc['db']
    cc = MongoConnection.class_config['site_filesystem']
    @mc_sitefs = MongoConnection.create :name => cc['name'],
                             :host => cc['host'],
                             :port => cc['port'],
                             :db => cc['db']
    cc = SolrConnection.class_config['default']
    @sc = SolrConnection.create :name => cc['name'],
                                :url => cc['url'],
                                :options => cc['options']
  end

  it "can be saved with valid user_id" do
    lambda {
      Site.create! :name => 'test1'
    }.should raise_exception
    @user.sites.create! :name => 'test2'
  end

  it 'can choose valid page from url' do
    site = @user.sites.create! :name => 'test3'
    p1 = site.pages.create :name => 'pages-a/_id_.html', :editable_content => ''
    p2 = site.pages.create :name => 'pages-b/いろはに.html', :editable_content => ''
    p3 = site.pages.create :name => 'pages-c/_ID_.html', :editable_content => ''
    p4 = site.pages.create :name => 'pages-d/test/list.html', :editable_content => ''
    p5 = site.pages.create :name => 'pages-_ID_.html', :editable_content => ''
    p6 = site.pages.create :name => '_p1_-_ID_.html', :editable_content => ''
    p7 = site.pages.create :name => 'xyz-_p2_.html', :editable_content => ''
    site.pages(true)
    site.matched_page('pages-a/test999.html').should == [p1, {'id' => 'test999'}]
    site.matched_page('pages-b/いろはに.html').should == [p2, {}]
    site.matched_page('pages-c/あいうえおabcスーパー.html').should == [p3, {'ID' => 'あいうえおabcスーパー'}]
    site.matched_page('pages-d/test/list.html').should == [p4, {}]
    site.matched_page('pages-登り.html').should == [p5, {'ID' => '登り'}]
    site.matched_page('ところで-登り.html').should == [p6, {'p1' => 'ところで', 'ID' => '登り'}]
    site.matched_page('xyz-下り.html').should == [p7, {'p2' => '下り'}]
  end

  it 'can copy contents from other site.' do
    site = @user2.sites.create! :name => 'mysite'
    site_from = @user.sites.create! :name => 'test3', :clonable => true
    site_from.pages.create :name => 'pages-a/_id_.html', :editable_content => ''
    site_from.pages.create :name => 'pages-b/いろはに.html', :editable_content => ''
    site.copy_from site_from
    site.pages(true)
    site.matched_page('pages-a/test999.html')[1].should == {'id' => 'test999'}
    site.matched_page('pages-b/いろはに.html')[1].should == {}
  end
  it 'can copy contents from other site by id.' do
    site_from = @user.sites.create! :name => 'test4', :clonable => true
    site_from.pages.create :name => 'pages-a/_id_.html', :editable_content => ''
    site_from.pages.create :name => 'pages-b/いろはに.html', :editable_content => ''
    site = @user2.sites.create! :name => 'mysite2', :source_site_id => site_from.id
    site.matched_page('pages-a/test999.html')[1].should == {'id' => 'test999'}
    site.matched_page('pages-b/いろはに.html')[1].should == {}
  end
  it 'can copy all files within mongo.' do
    ot = @user.one_tables.create :name => 'vf3',
                                 :template_file => 'spec/files/sites/one-table-template-file.xls'
    headers = [['マーカー種別', :string], ['利用日付', :time], ['合計', :integer], ['備考', :text]]
    rows = [
            ['abc', Time.parse('2009/9/30'), 123, 'これは備考です。abc-xを含みます。'],
            ['いろは', nil, 456, 'これは一つのペンです。'],
            ['xyz', Time.parse('2010/6/21'), -1, 'これは別の例Dです。'],
            ['ABC', Time.parse('2001/5/10'), -2500, 'これは大文字の例です。ABCが入っています。'],
           ]
    ot.headers = headers
    ot.rows = rows
    MongoFiles.new('test5').destroy
    MongoFiles.new('test5').list_names.should == []
    MongoFiles.new('mysite5').destroy
    MongoFiles.new('mysite5').list_names.should == []
    site_from = @user.sites.create! :name => 'test5', :clonable => true
    site_from.import_files 'spec/files/sites/pages-b.zip'
    site_from.pages.create :name => 'pages-b/いろはに.html', :editable_content => '<html><head>ho</head></html>'
    site_from.blocks.map(&:name).should == ['body-content']
    site_from.blocks[0].update_attributes :one_table_id => ot.id
    site_from.site_attributes.create :key => 'ho', :value => 'yo'
    site = @user2.sites.create! :name => 'mysite5aa', :source_site_id => site_from.id
    site.matched_page('index.html')[1].should == {}
    site.pages(true).map(&:name).sort.should == ['index.html', 'pages-b/いろはに.html']
    site.pages.find_by_name('pages-b/いろはに.html').editable_content.should == '<html><head>ho</head></html>'
    file_list0 = ['images/RouenNotreDame.jpg', 'images/tomcat.gif',
                  'index.html',
                  'javascripts/controls.js',
                  'javascripts/prototype.js',
                  'stylesheets/scaffold.css']
    site.files.list_names.sort.should == file_list0
    site.site_files.map(&:path).sort.should == file_list0
    site.import_files 'spec/files/sites/example2.zip', :generate_pages => false
    file_list = ['favicon.ico',
                 'images/RouenNotreDame.jpg',
                 'images/face-s-00.png',
                 'images/face06s.png',
                 'images/tomcat.gif',
                 'index.html',
                 'javascripts/controls.js',
                 'javascripts/prototype.js',
                 'robots.txt',
                 'stylesheets/scaffold.css'
    ]
    site.files.list_names.sort.should == file_list
    site.site_files.map(&:path).sort.should == file_list
    site.site_attributes(true).size.should == 1
    [:key, :value].map { |meth| site.site_attributes[0].send(meth) }.should == ['ho', 'yo']
    site.blocks.map(&:name).should == ['body-content']
    ot2 = site.blocks[0].one_table
    ot2.user.id.should == @user2.id
    ot2.template_file.content.should == File.open('spec/files/sites/one-table-template-file.xls', 'rb').read
    oths_attrs = ot.one_table_headers.map { |oth| remove_active_record_specific_attrs(oth, 'one_table_id') }
    ot2hs_attrs = ot2.one_table_headers.map { |oth| remove_active_record_specific_attrs(oth, 'one_table_id') }
    oths_attrs.should == ot2hs_attrs
    site.destroy
    site.files.list_names.should == []
    Page.find_all_by_site_id(site.id).should == []

  end
  it 'should keep multiple attributes per site.' do
    site = @user.sites.create! :name => 'test5ref'
    site.site_attributes.should == []
    sas = site.attrs
    site.attrs[:a] = 'いろは'
    site2 = Site.find site.id
    site2.attrs['a'].should == 'いろは'
  end
  it 'should hold option values within AdminOption instance.' do
    site = @user.sites.create! :name => 'test5ref-ao'
    site.admin_options.should == {}
    site.admin_options[:theme] = 'default-classic'
    ao1 = AdminOption.find site.admin_option.id
    ao1.attrs.should == {}
    site.save
    ao2 = AdminOption.find site.admin_option.id
    ao2.attrs.should == { 'theme' => 'default-classic' }

    site.clonable.should == false
    site2 = @user2.sites.create! :name => 'test5ref-ao-2'
    lambda {
      site2.copy_from site
    }.should raise_error
    site.update_attributes :clonable => true
    site2.copy_from site
    site2.admin_options.should == { 'theme' => 'default-classic' }
  end
  it 'should be owned by creator.' do
    site1 = @user.sites.create! :name => 'test5ref-ao'
    site1.admin?(@user).should be_true
    site1.admin?(@user2).should_not be_true
  end
=begin
  it 'should lookup name for virtualhost.' do
    @user.sites.create! :name => 'test5ref01', :virtualhost => 'ho.jp'
    Site.lookup_name_for_virtualhost('ho.jp').should == 'test5ref01'
    Site.lookup_name_for_virtualhost('yo.jp').should be_nil
    @user.sites.create! :name => 'test5ref02', :virtualhost => 'yo.jp'
    Site.lookup_name_for_virtualhost('yo.jp').should be_nil
    sleep 2
    Site.lookup_name_for_virtualhost('yo.jp').should == 'test5ref02'
  end
=end
  it 'should rename site name.' do
    site = @user.sites.create! :name => 'test4mv-before'
    site.import_files 'spec/files/sites/pages-b.zip'
    site.files.list_names.sort.should == ['images/RouenNotreDame.jpg', 'images/tomcat.gif',
                                          'index.html',
                                          'javascripts/controls.js',
                                          'javascripts/prototype.js',
                                          'stylesheets/scaffold.css']
    site.update_attributes :name => 'test4mv-after'
    site.files(true).list_names.sort.should == ['images/RouenNotreDame.jpg', 'images/tomcat.gif',
                                          'index.html',
                                          'javascripts/controls.js',
                                          'javascripts/prototype.js',
                                          'stylesheets/scaffold.css']
  end
  it 'should save/load site#description,title.' do
    site0 = @user.sites.create! :name => 'test4description-and-title'
    site0.description.should be_nil
    site0.description = 'こんにちはサイト'
    site0.save
    site1 = Site.find site0.id
    site1.description.should == 'こんにちはサイト'
    site2 = Site.find site0.id
    site2.title = '平成23年度前期'
    site2.save
    site3 = Site.find site2.id
    site3.title.should == '平成23年度前期'
  end
  after(:each) do
    @user.destroy
    @user2.destroy
    @mc.destroy
    @mc_gfs.destroy
    @mc_sitefs.destroy
    @sc.destroy
  end
  private
  def remove_active_record_specific_attrs(ar, *other_keys)
    other_keys = [other_keys].flatten
    attrs = ar.attributes.clone
    attrs.delete 'id'
    attrs.delete 'created_at'
    attrs.delete 'updated_at'
    other_keys.each do |other_key|
      attrs.delete other_key
    end
    attrs
  end
end
