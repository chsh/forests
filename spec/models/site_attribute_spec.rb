# encoding: UTF-8
require 'spec_helper'

describe SiteAttribute do

  before(:each) do
    @user = create :user
    @site = @user.sites.create :name => 'new-site'
  end
  after(:each) do
    @user.destroy
  end
  it "should create a new instance given valid attributes" do
    # no site_id causes error.
    lambda {
      SiteAttribute.create!(:key => "value for key",
                            :value => "value for value")
    }.should raise_error
    SiteAttribute.create!(:site_id => 1,
                          :key => "value for key",
                          :value => "value for value").class.should == SiteAttribute

    # duplicated key causes error.
    lambda {
      SiteAttribute.create!(:site_id => 1,
                            :key => "value for key",
                            :value => "value for value")
    }.should raise_error

    # empty value is ok.
    SiteAttribute.create!(:site_id => 1,
                          :key => 'value for key 2').class.should == SiteAttribute

  end

  it 'should create file within site.files.' do
    sa = @site.site_attributes.create :key => 'image-file',
                                     :file => 'spec/files/site_attributes/duke-logo.png'
    c = File.open('spec/files/site_attributes/duke-logo.png', 'rb').read
    fc = @site.files.content(sa.value)
    (fc == c).should == true
    sa2 = SiteAttribute.find sa.id
    sa2.file?.should == true
    sa2value = sa2.value
    sa2.update_attributes :file => 'spec/files/site_attributes/file2.jpg'
    sa2.image?.should == true
    sa2.image_size.width.should == 122
    sa2.image_size.height.should == 140
    sa3 = SiteAttribute.find sa2.id
    sa3.file?.should == true
    sa3value = sa3.value
    @site.files.exist?(sa2value).should == false
    (sa3value == sa2value).should == false
    c2 = File.open('spec/files/site_attributes/file2.jpg', 'rb').read
    fc2 = @site.files.content(sa3.value)
    (fc2 == c2).should == true
    sa3.render_content('images/sizes/dir1/test.html').should == "<img src='../../../#{sa3.value}' width='122' height='140'/>"
    sa3.destroy
    @site.files.exist?(sa3.value).should == false
  end

  it 'should treat metadata.' do
    sa = @site.site_attributes.create :key => 'test-key',
                                      :value => 'テスト値'
    sa.protected_key?.should == false
    sa2 = @site.site_attributes.create :key => 'test-key-2',
                                       :value => 'テスト値2',
                                       :protected_key => true
    sa2.protected_key?.should == true

  end

  it 'should provide attributes using attributes_for_new_instance.' do
    sa1 = @site.site_attributes.create :key => 'test-key',
                                       :value => 'テスト値'
    ni1 = sa1.attributes_for_new_instance
    ni1.slice('key', 'value', 'metadata').should == {
            'key' => 'test-key',
            'value' => 'テスト値',
            'metadata' => {}
    }
    ni1['file'].should be_nil
    sa2 = @site.site_attributes.create :key => 'test-key-file',
                                       :file => 'spec/files/site_attributes/file2.jpg'
    ni2 = sa2.attributes_for_new_instance
    ni2.slice('key', 'value', 'metadata').should == {
            'key' => 'test-key-file',
            'value' => sa2.value,
            'metadata' => {'image_size' => '122x140'}
    }

    ni2['file'].class.should == MongoFile
    ni2['file'].path.should == sa2.value
    ni2['file'].mongo_files.name.should == @site.files.name
    ni2['file'].mongo_files.opts.should == @site.files.opts
  end

end
