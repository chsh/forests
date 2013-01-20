# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :one_table_template do
    sequence(:name) { |n| "one-table-template-{n}" }
    output_format 1
    output_encoding 'cp932'
    output_lf 1
  end
end
