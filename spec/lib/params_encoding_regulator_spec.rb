# encoding: UTF-8
require "spec_helper"

require 'nkf'

describe ParamsEncodingRegulator do

  it "should should convert encodings to utf8." do
    er = ParamsEncodingRegulator.new :marker_key => 'em'
    params_sjis = {
            :em => NKF.nkf('-sW', '京'),
            :ht => NKF.nkf('-sW', '表計算'),
            :h0 => NKF.nkf('-sW', '一にさん'),
            :hi => NKF.nkf('-sW', '〜'),
            :action => NKF.nkf('-sW', 'default'),
    }
    er.regulate params_sjis
    params_sjis.should == {
            :em => '京',
            :ht => '表計算',
            :h0 => '一にさん',
            :hi => '〜',
            :action => 'default'
    }

    params_euc = {
            :em => NKF.nkf('-eW', '京'),
            :ht => NKF.nkf('-eW', '表計算'),
            :h0 => NKF.nkf('-eW', '一にさん'),
            :hi => NKF.nkf('-eW', '〜'),
            :action => NKF.nkf('-eW', 'default'),
    }
    er.regulate params_euc
    params_euc.should == {
            :em => '京',
            :ht => '表計算',
            :h0 => '一にさん',
            :hi => '〜',
            :action => 'default'
    }

    params_jis = {
            :em => NKF.nkf('-jW', '京'),
            :ht => NKF.nkf('-jW', '表計算'),
            :h0 => NKF.nkf('-jW', '一にさん'),
            :hi => NKF.nkf('-jW', '〜'),
            :action => NKF.nkf('-jW', 'default'),
    }
    er.regulate params_jis
    params_jis.should == {
            :em => '京',
            :ht => '表計算',
            :h0 => '一にさん',
            :hi => '〜',
            :action => 'default'
    }

    params_utf8 = {
            :em => '京',
            :ht => '表計算',
            :h0 => '一にさん',
            :hi => '〜',
            :action => 'default'
    }
    er.regulate params_utf8
    params_utf8.should == {
            :em => '京',
            :ht => '表計算',
            :h0 => '一にさん',
            :hi => '〜',
            :action => 'default'
    }

    params_no_em = {
            :ht => NKF.nkf('-sW', '表計算'),
            :h0 => NKF.nkf('-sW', '一にさん'),
            :hi => NKF.nkf('-sW', '〜'),
            :action => NKF.nkf('-sW', 'default'),
    }
    er.regulate params_no_em
    params_no_em.should == {
            :ht => NKF.nkf('-sW', '表計算'),
            :h0 => NKF.nkf('-sW', '一にさん'),
            :hi => NKF.nkf('-sW', '〜'),
            :action => NKF.nkf('-sW', 'default'),
    }

    params_sjis_string_em = {
            'em' => NKF.nkf('-sW', '京'),
            :ht => NKF.nkf('-sW', '表計算'),
            :h0 => NKF.nkf('-sW', '一にさん'),
            :hi => NKF.nkf('-sW', '〜'),
            :action => NKF.nkf('-sW', 'default'),
    }
    er.regulate params_sjis_string_em
    params_sjis_string_em.should == {
            'em' => '京',
            :ht => '表計算',
            :h0 => '一にさん',
            :hi => '〜',
            :action => 'default'
    }

    params_sjis_with_complex_type = {
            :em => NKF.nkf('-sW', '京'),
            :ht => NKF.nkf('-sW', '表計算'),
            :h0 => NKF.nkf('-sW', '一にさん'),
            :hi => NKF.nkf('-sW', '〜'),
            :cc => ['アレイ'],
            :action => NKF.nkf('-sW', 'default'),
    }
    er.regulate params_sjis_with_complex_type
    params_sjis_with_complex_type.should == {
            :em => '京',
            :ht => '表計算',
            :h0 => '一にさん',
            :hi => '〜',
            :cc => ['アレイ'],
            :action => 'default'
    }
  end
end
