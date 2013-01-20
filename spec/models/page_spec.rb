# encoding: UTF-8
require 'spec_helper'

describe Page do

  before(:each) do
    @user = create :user
    @site = @user.sites.create :name => 'test1'
    @site.site_attributes.create :key => 'hoge1', :value => 'ほげ'
    @site.site_attributes.create :key => 'ほげ2', :value => 'Ｈｏｇｅ'
    @sa_file = @site.site_attributes.create :key => 'imagefile', :file => 'spec/files/page/file1.png'
  end

  after(:each) do
    @site.destroy
  end

  it 'should extract url to regexp' do
    page = @site.pages.create :name => 'ids/_list_/_uid_.html', :editable_content => ''
    page.path_regexp.should == '^ids/\b([^\/]+?)\b/\b([^\/]+?)\b.html$'
    page.url_keys.should == ['list', 'uid']
  end

  it 'returns matched hash' do
    page = @site.pages.create :name => 'ids/_リスト_/_uid_.html', :editable_content => ''
    page.match_hash('ids/沖縄県/43210.html').should == {
      'uid' => '43210', 'リスト' => '沖縄県'
    }
    page.match_hash('ids/沖縄/県/43210.html').should be_nil
  end

  it 'can create blocks' do
    @site.blocks.size.should == 0
    page = @site.pages.create :name => 'ids/_list_/_uid_.html',
                       :editable_content => '<tag ot="ot1"><span>テスト</span></tag>'
    @site.blocks(true).size.should == 1
    @site.blocks[0].block_contents.size.should == 1
    bc = @site.blocks[0].block_contents[0]
    bc.content.gsub(/\s+/, '').should == '<tag><span>テスト</span></tag>'
    bc.content_type.should == 'text/html'
    @site.blocks[0].refered_pages.should == [page]
  end

  it 'has keys by content' do
    page = @site.pages.create :name => 'test001.html',
                       :editable_content => '<tag ot="ot2"><span>テスト</span></tag><tag ot="ot1">test</tag>'
    page.block_keys.sort.should == ['ot1', 'ot2']
    block = @site.blocks.find_by_name 'ot2'
    block.update_attributes :content_type => 'text/html',
                            :content => '<div style="width: 100%; height: 50px"><h1>テスト</h1></div>'
    page2 = @site.pages(true).find_by_name 'test001.html'
    page2.editable_content.should == "<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\" \"http://www.w3.org/TR/REC-html40/loose.dtd\">\n<html xmlns=\"http://www.w3.org/1999/xhtml\" xmlns=\"http://www.w3.org/1999/xhtml\">\n    <body>\n        <div ot=\"ot2\" style=\"width: 100%; height: 50px\"><h1>テスト</h1></div><tag ot=\"ot1\">test</tag></body>\n</html>\n"
  end

  it 'can render content' do
    page = @site.pages.create :name => 'test001_render.html',
                              :editable_content => '<div id="test"><div id="i1"><tag ot="ot2"><span>テスト</span></tag></div><div id="i2"><tag ot="ot2"></tag></div></div>'

    block_ot2 = @site.blocks.find_by_name 'ot2'
    block_ot2.update_attributes :name => 'ot2', :content => '<ul><li>新しい項目</li></ul>', :content_type => 'text/html'
    rc = "<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\" \"http://www.w3.org/TR/REC-html40/loose.dtd\">\n<html xmlns=\"http://www.w3.org/1999/xhtml\">\n    <body>\n        <div id=\"test\">\n            <div id=\"i1\">\n                <ul><li>新しい項目</li></ul>\n            </div>\n            <div id=\"i2\">\n                <ul><li>新しい項目</li></ul>\n            </div>\n        </div>\n    </body>\n</html>\n"
    page.render_content.gsub(/\s+/, '').should == rc.gsub(/\s+/, '')
  end

  it 'duplicate block name must cause error' do
    @site.pages.create :name => 'test001_render.html',
                              :editable_content => '<div id="test"><div id="i1"><tag ot="ot2"><span>テスト</span></tag></div><div id="i2"><tag ot="ot2"></tag></div></div>'
    lambda {
      @site.blocks.create :name => 'ot2'
    }.should raise_exception
  end

  it 'does not push block if empty.' do
    page = @site.pages.create :name => 'test00_push_empty.html',
                       :editable_content => '<tag ot="ot1"><span>テスト</span></tag>'
    @site.blocks(true)[0].block_contents[0].content.gsub(/\s+/, '').should == '<tag><span>テスト</span></tag>'
    page.update_attributes :editable_content => '<tag ot="ot1"></tag>'
    @site.blocks(true)[0].block_contents[0].content.gsub(/\s+/, '').should == '<tag><span>テスト</span></tag>'
  end

  it 'does not escape japanese chars in link.' do
    @site.pages.create :name => 'test01_unescape_jp.html',
                       :editable_content => File.read('spec/files/page/kamoku.html')
    @site.blocks(true)[0].block_contents[0].content.gsub(/\s*\n+\s*/, '').should == "<div repeat=\"_科目グループ_\"><h3>_科目グループ_</h3><ul class=\"kamoku\"><li repeat=\"_科目グループサブ_\"><a href=\"s-_科目グループサブ_.html\">_科目グループサブ_</a></li><br class=\"clear\" /></ul></div>"

  end

  it 'should render site attributes.' do
    page = @site.pages.create :name => 'test/1/2/test001_site_attributes.html',
                              :editable_content => '<div id="test"><span>_site:imagefile_</span>_site:hoge1_<div id="i1"><tag ot="ot2"><span>テスト _site:ほげ2_ </span></tag></div><div id="i2">Hello _site:ほげ2_ _site:not_key_ </div></div>'
    rc = <<EOL
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">
<html xmlns="http://www.w3.org/1999/xhtml"><body>
        <div id="test">
<span><img src="../../../#{@sa_file.value}" width="#{@sa_file.image_size.width}" height="#{@sa_file.image_size.height}"></span>ほげ<div id="i1"><tag><span>テスト _site:ほげ2_ </span>
</tag></div>
<div id="i2">Hello Ｈｏｇｅ <span title="Key(not_key) not found." style="color:red;font-weight:bold">_site:not_key_</span> </div>
</div>
    </body></html>
EOL
    page.render_content.gsub(/\n+/, '').should == rc.gsub(/\n+/, '')
  end
  it 'should hold description within admin_option.' do
    page = @site.pages.create :name => 'test/1/2/3/test001_site_attributes.html',
                              :editable_content => '<div id="test"><span>_site:imagefile_</span>_site:hoge1_<div id="i1"><tag ot="ot2"><span>テスト _site:ほげ2_ </span></tag></div><div id="i2">Hello _ほげ2_ _site:not_key_ </div></div>'
    page.description.should be_nil
    page.description = 'Hello, Desc.'
    p1 = Page.find page.id
    p1.description.should be_nil
    page.save
    b2 = Page.find page.id
    b2.description.should == 'Hello, Desc.'
  end
  it 'can render content with google analytics with NO-BLOCK.' do
    page = @site.pages.create :name => 'test001_render.html',
                              :editable_content => '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"><html><head><title>T</title></head><body id="i1"><tag><span>テスト</span></tag><div id="i2"></div></body></html>'
    rc0 = <<EOL
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html><head><title>T</title></head><body id="i1"><tag><span>テスト</span></tag><div id="i2"></div></body></html>
EOL
    page.render_content.gsub(/\s+/, '').should == rc0.gsub(/\s+/, '')

    rc1 = <<EOL
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>T</title>
</head>
<body id="i1">
        <tag><span>テスト</span>
        </tag><div id="i2"></div>
        <script type="text/javascript">
<![CDATA[
  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', 'UA-12345-6']);
  _gaq.push(['_trackPageview']);
  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();
]]>
        </script>
</body>
</html>
EOL
    @site.attrs['google_analytics_ua'] = 'UA-12345-6'
    page = Page.find(page)
    page.render_content.gsub(/\s+/, '').should == rc1.gsub(/\s+/, '')
  end

  it 'can render content with google analytics with ENTIRE-BLOCK.' do
    page = @site.pages.create :name => 'test001_render.html',
                              :editable_content => '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"><html ot="ot12"><head><title>T</title></head><body id="i1"><tag><span>テスト</span></tag><div id="i2"></div></body></html>'
    rc0 = <<EOL
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>T</title>
</head>
<body id="i1">
        <tag><span>テスト</span>
        </tag><div id="i2"></div>
    </body>
</html>
EOL
    page.render_content.gsub(/\s+/, '').should == rc0.gsub(/\s+/, '')

    rc1 = <<EOL
<script type="text/javascript">
<![CDATA[
  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', 'UA-12345-6']);
  _gaq.push(['_trackPageview']);
  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();
]]>
</script>
EOL
    @site.attrs['google_analytics_ua'] = 'UA-12345-6'
    page = Page.find(page)
    puts "page.editable_content:#{page.editable_content}"
    page.render_content.gsub(/\s+/, '').index(rc1.gsub(/\s+/, '')).should > 0
  end

=begin
  it 'should render pdf' do
    page = @site.pages.create name: 'test002_render.pdf',
                              editable_content: '<html><head><title>Hello</title></head><body>こんにちはPDF</body></html>'
    html = content_pdf_to_html page.render_content
    html.force_encoding('BINARY')
    html = remove_meta_date html
    fc = File.open('spec/files/page/test002_render.html', 'rb').read
    fc = remove_meta_date fc
    html.should == fc
  end
=end

  it 'should eval ruby script.' do
    page = @site.pages.create name: 'test002_render.rb',
                              editable_content: '<<EOL
<b>#{params[:keys]}</b>
EOL
'
    page.render_content({keys: 'abc'}, {vals: 'val1,val2'}).should == "<b>abc</b>\n"
  end

  it 'should return content-type from page attribute.' do
    page1 = @site.pages.create name: 'test002_render.rb',
                              editable_content: 'abc/いろは/xyz',
                              language: 'text'
    page1.render_content.should == 'abc/いろは/xyz'

    page2 = @site.pages.create name: 'test002_render.json',
                              editable_content: 'params[:content_type] = "application/json"; "abc"',
                              language: 'ruby'
    ps = {}
    page2.render_content(ps).should == 'abc'
    ps[:content_type].should == 'application/json'
  end

  private
  def remove_meta_date(html)
    html.gsub /<META name="date" content="[^"]+"/i, '<META name="date" content=""'
  end
  def content_pdf_to_html(content_pdf)
    tf = Tempfile.new('pdf', encoding: 'BINARY')
    tf.write content_pdf
    tf.close
    html = `pdftohtml -enc UTF-8 -noframes -stdout #{tf.path}`
    tf.close(true)
    html
  end
end
