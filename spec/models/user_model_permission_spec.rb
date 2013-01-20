# coding: UTF-8

require 'spec_helper'

describe UserModelPermission do
  before(:each) do
    User.destroy_all
  end
  after(:each) do
    User.destroy_all
  end
end
