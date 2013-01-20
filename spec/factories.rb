# -*- coding: utf-8 -*-
# This will guess the User class
# for more info, see. https://github.com/thoughtbot/factory_girl/blob/master/GETTING_STARTED.md
FactoryGirl.define do
  factory :user do
    sequence(:login) { |n| "login-account-#{n}" }
    password 'pass2010'
    password_confirmation 'pass2010'
    level User::LEVEL_ADMIN
  end
  factory :site_admin_user, class: User do
    email 'test-site-admin@example.com'
    password 'pass2010'
    password_confirmation 'pass2010'
    level User::LEVEL_EDITABLE
  end
  factory :inactive_user, class: User, aliases: %w(default_user) do
    login 'non-active'
    email 'test-inactive@example.com'
    password 'pass2010'
    password_confirmation 'pass2010'
  end
  factory :site_user, class: User do
    login 'site-user'
    email 'test-site@example.com'
    password 'pass2010'
    password_confirmation 'pass2010'
    level User::LEVEL_VIEWABLE
  end

  factory :one_table do
    sequence(:name) { |n| "hello-one-table-#{n}" }
    user
  end

  factory :one_table_header do
    sequence(:label) { |n| "タイトル#{n}" }
    kind OneTableHeader::KIND_TEXT
  end

  # one_table_template factory is described at factories/ott.rb
end
