require 'nkf'
require 'iconv'

class ParamsEncodingRegulator
  CONVERTERS = {
          :jis => Iconv.new('UTF-8', 'ISO-2022-JP'),
          :sjis => Iconv.new('UTF-8', 'SJIS'),
          :euc => Iconv.new('UTF-8', 'EUC-JP')
  }
  def initialize(opts = {})
    opts.reverse_merge! :marker_key => :em
    @opts = {}
    @opts[:marker_key_sym] = opts[:marker_key].to_sym
    @opts[:marker_key_s] = opts[:marker_key].to_s
  end
  def regulate(params)
    mv = marker_value(params)
    return params unless mv
    case NKF.guess(mv)
    when NKF::JIS then cv = CONVERTERS[:jis]
    when NKF::EUC then cv = CONVERTERS[:euc]
    when NKF::SJIS then cv = CONVERTERS[:sjis]
    else cv = nil
    end
    return params unless cv
    params.keys.each do |key|
      v = params[key]
      params[key] = cv.iconv(v) if v.is_a? String
    end
    params
  end
  private
  def marker_value(params)
    params[@opts[:marker_key_sym]] || params[@opts[:marker_key_s]]
  end
end
