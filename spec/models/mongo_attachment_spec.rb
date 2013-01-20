# encoding: UTF-8
require 'spec_helper'

describe MongoAttachment do
  before do
    @user = create :user
    cc = MongoConnection.class_config['default_gridfs']
    @mc_gfs = MongoConnection.create :name => cc['name'],
                             :host => cc['host'],
                             :port => cc['port'],
                             :db => cc['db']
  end

  it 'can save file by path' do
    ma = MongoAttachment.create :user_id => @user.id,
                                :file => "#{Rails.root}/spec/files/mongo_attachment/mongo_attachment.data"
    ma.content.force_encoding('UTF-8').should == "いろはにほ\n"
  end

  it 'can have returning static path method' do
    ma = MongoAttachment.create :user_id => @user.id,
                                :file => "#{Rails.root}/spec/files/mongo_attachment/mongo_attachment.data"
    File.open(ma.filepath).read.should == "いろはにほ\n"
  end

  it 'can save only once.' do
    target = "#{Rails.root}/spec/files/mongo_attachment/mongo_attachment.data"
    ma = MongoAttachment.create :user_id => @user.id
    ma.content_size.should == nil
    ma.content_md5.should == nil
    ma.update_attributes :file => target
    ma.content_size.should == File.size(target)
    ma.content_md5.should == File.md5(target)
    ma2 = MongoAttachment.create :user_id => @user.id,
                                 :file => target
    ma2.content_size.should == File.size(target)
    ma2.content_md5.should == File.md5(target)
    ma2.update_attributes :file => "#{Rails.root}/spec/files/mongo_attachment/mongo_attachment.2.data"
    ma2.content_size.should == File.size(target)
    ma2.content_md5.should == File.md5(target)
  end

  after do
    @mc_gfs.destroy
  end
end
