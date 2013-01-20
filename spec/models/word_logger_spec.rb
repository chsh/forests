# -*- coding: UTF-8 -*-

require 'spec_helper'

describe WordLogger do
  before(:each) do
    @user = create :inactive_user
    @site = @user.sites.create name: 'test-site-1'
    LoggedWord.delete_all
    LoggedWordSearchActivity.delete_all
    SearchActivity.delete_all
  end
  it 'should create log from parameters' do
    params = { 'ht' => 'テスト　コード', 'h100' => 'TEST　SUCCESS  '}
    WordLogger.log(@site, params)
    @site.logged_words.words.sort.should == %w(success test コード テスト)
  end
  it 'should count search times.' do
    WordLogger.log(@site, { 'ht' => 'TEST' })
    WordLogger.log(@site, { 'ht' => 'TEST word' })
    @site.logged_words.map { |lw|
      [lw.value, lw.count]
    }.should == [['test', 2], ['word', 1]]
  end
  it 'should count search activities' do
    WordLogger.log(@site, { 'ht' => 'TEST' })
    WordLogger.log(@site, { 'ht' => 'ワード' })
    @site.search_activities.count.should == 2
  end
end
