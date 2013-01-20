# -*- coding: UTF-8 -*-
require 'spec_helper'

describe OneTableHook do
  it 'should be created with valid attributes.' do
    lambda {
      OneTableHook.create!
    }.should raise_error
    ot = OneTable.create name: 'hello', user_id: 1
    lambda {
      ot.hooks.create! code: 'puts "hello"', on: 'after:no-action'
    }.should raise_error # wrong on value
    target_file = File.join(Rails.root, 'tmp/hook.action')
    File.delete(target_file) if File.exist?(target_file)
    otk = ot.hooks.create! code: "File.open('#{target_file}', 'w') { |f| f.puts 'hello' }", on: 'after:save'
    otk.id.should_not be_nil
    File.exist?(target_file).should_not be_true
    ot.save!
    # only rows modification cause to run hooks.
    File.exist?(target_file).should_not be_true

    headers = [['マーカー種別', :string], ['利用日付', :time], ['合計', :integer], ['備考', :text]]
    rows = [
            ['abc', Time.parse('2009/9/30'), 123, 'これは備考です。abc-xを含みます。'],
            ['abc', Time.parse('2009/8/30'), 124, 'これは備考です。abc-yを含みます。'],
    ]
    ot.headers = headers
    ot.rows = rows

    File.read(target_file).should == "hello\n"
    File.delete(target_file)

    otk.update_attributes code: "File.open('#{target_file}', 'w') { |f| f.puts 'updated' }"
    r1 = ot.record ot.row_ids[0]
    r1.update_attributes({})
    File.read(target_file).should == "updated\n"

    otk.update_attributes code: "File.open('#{target_file}', 'w') { |f| f.puts 'created' }"
    r2 = ot.record
    r2.update_attributes({})
    File.read(target_file).should == "created\n"

    otk.update_attributes code: "File.open('#{target_file}', 'w') { |f| f.puts 'deleted' }"
    r3 = ot.record ot.row_ids[0]
    r3.destroy
    File.read(target_file).should == "deleted\n"

    File.delete(target_file)
  end
end
