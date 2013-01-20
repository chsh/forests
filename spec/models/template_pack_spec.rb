require 'spec_helper'

describe TemplatePack do
  before do
    @user = create :user
  end

  it "can show site list from someone's." do
    site1 = @user.sites.create! :name => '01.test1', :clonable => true
    @user.sites.create! :name => '02.test2'
    site3 = @user.sites.create! :name => '03.test3', :clonable => true
    css = TemplatePack.clonable_sites
    css.map(&:class).should == [Site, Site]
    css.map(&:name).should == ['01.test1', '03.test3']
    css.map(&:index_url).should == ['/01.test1/index.html', '/03.test3/index.html']
    css.map(&:id).should == [site1.id, site3.id]
  end
end
