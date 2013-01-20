# encoding: UTF-8
require "spec_helper"

describe RepetitionExtractor do

  it "should can parse some texts." do
    source = <<EOL
<div repeat="main">
  _maincode_ _main_ のヘルプ
  <ul>
  <li repeat="sub">
    ここに副項目としての _subcode_ _sub_
    <span repeat="title">_title_ これはタイトル</span>
  </li>
  </ul>
</div>
EOL
    r = RepetitionExtractor.new(source)
    r.root_text.should == '[:main:]'
    r.fragment_map.should == {
        "[:sub:]"=>"  <li>\n  \n    ここに副項目としての _subcode_ _sub_\n    \n[:title:]\n\n  \n  </li>\n",
        "[:title:]"=>"  <span>\n  _title_ これはタイトル\n  </span>\n",
        "[:main:]"=>"  <div>\n  \n  _maincode_ _main_ のヘルプ\n  \n  <ul>\n  [:sub:]\n\n  \n  </ul>\n\n  </div>\n"
    }

    headers = %w(maincode main subcode sub title)
    rows = [
            %w(1 ア 1 い A),
            %w(1 ア 1 い B),
            %w(1 ア 2 ろ C),
            %w(1 ア 2 ろ D),
            %w(1 ア 2 ろ E),
            %w(1 ア 3 は A),
            %w(1 ア 3 は C),
            %w(1 ア 3 は E),
            %w(1 ア 3 は F),
            %w(2 イ 4 に A),
            %w(2 イ 4 に B),
            %w(2 イ 5 い A),
            %w(2 イ 5 い B),
            %w(2 イ 6 ほ G)
    ]
    expected_result = <<EOL
<div>
  1 ア のヘルプ
  <ul>
  <li>
    ここに副項目としての 1 い
    <span>A これはタイトル</span>
    <span>B これはタイトル</span>
  </li>
  <li>
    ここに副項目としての 2 ろ
    <span>C これはタイトル</span>
    <span>D これはタイトル</span>
    <span>E これはタイトル</span>
  </li>
  <li>
    ここに副項目としての 3 は
    <span>A これはタイトル</span>
    <span>C これはタイトル</span>
    <span>E これはタイトル</span>
    <span>F これはタイトル</span>
  </li>
  </ul>
</div>
<div>
  2 イ のヘルプ
  <ul>
  <li>
    ここに副項目としての 4 に
    <span>A これはタイトル</span>
    <span>B これはタイトル</span>
  </li>
  <li>
    ここに副項目としての 5 い
    <span>A これはタイトル</span>
    <span>B これはタイトル</span>
  </li>
  <li>
    ここに副項目としての 6 ほ
    <span>G これはタイトル</span>
  </li>
  </ul>
</div>
EOL
    expected_result = expected_result.gsub(/\s*\n+\s*/, '').strip
    tr1 = TableReader.new headers, rows
    r.render(tr1).gsub(/\s*\n+\s*/, '').strip.should == expected_result
    tr2 = TableReader.new nil, []
    r.render(tr2).gsub(/\s*\n+\s*/, '').strip.should == ''
  end

  it "return nil if root tag doesn't have 'repeat' attribute." do
    source1 = <<EOL
  <div>
    <div repeat="sub">
      ここに副項目としての _sub_
    </div>
  </div>
EOL
    RepetitionExtractor.from(source1).should be_nil
    source2 = <<EOL
  <div repeat="main">
    <div repeat="sub">
      ここに副項目としての _sub_
    </div>
  </div>
EOL
    RepetitionExtractor.from(source2).class.should == RepetitionExtractor
  end
end
