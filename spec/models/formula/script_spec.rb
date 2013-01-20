# encoding: UTF-8
require "spec_helper"

describe Formula::Script do

  it "should should eval script content" do
    f = Formula::Script.new
    f.params = {
        :pairs => [['h5', 'h6'], ['h3', 'h4'], ['h1', 'h2']],
        :delimiter => '<br/>',
    }
    f.params[:script] = <<EOL
pairs = params[:pairs] || []
delim = params[:delimiter] || '<br/>'
r = []
pairs.each do |pair|
  vals = pair.map { |f| row[f] }
  next if vals[0].to_s == ''
  val = vals[0]
  val += delim + '(' + vals[1] + ')' unless vals[1].to_s =~ /^\s*$/
  r << val
end
r.join(delim)
EOL
    row = {
        'h0' => 'first cell',
        'h1' => 'いろは',
        'h2' => '会社',
        'h3' => nil,
        'h5' => 'だれか',
        'h6' => nil
    }
    f.eval(row).should == 'だれか<br/>いろは<br/>(会社)'
  end
end
