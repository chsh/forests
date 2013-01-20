# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :activity do
    user nil
    targetable_type "MyString"
    targetable_id 1
    action "MyString"
  end
end
