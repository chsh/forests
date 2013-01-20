# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :logged_word do
    site_id 1
    value "MyString"
  end
end
