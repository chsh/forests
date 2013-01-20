require 'cgi'

class PageBlockBuilder

  def initialize(page_content)
    @page_content = page_content
    @page_doc = Nokogiri::HTML(@page_content)
  end

  def to_page_content
    self.class.to_indented_xhtml @page_doc
  end

  def self.parse(page_content)
    new(page_content).parse
  end

  def self.merge(editable_content, html_blocks)
    doc = Nokogiri::HTML(editable_content, nil, 'UTF-8')
    ot_blocks = {}
    doc.xpath('//*[@ot]').each do |ot|
      name = ot['ot'].split(/;/).first
      if name == '-' || ot_blocks[name]
        # ignore
      else
        ot.attributes.keys.each do |atkey|
          ot.delete atkey unless atkey == 'ot'
        end
        frag_root = Nokogiri::HTML.fragment(html_blocks[name]).children[0]
        ot.name = frag_root.name
        frag_root.attributes.keys.each do |atkey|
          ot[atkey] = frag_root[atkey] unless atkey == 'ot'
        end
        ot_blocks[name] = true # mark as 'processed'
        ot.children.each { |c| c.remove }
        frag_root.children.to_a.each do |n|
          ot.add_child n
        end
      end
    end
    to_indented_xhtml doc
  end

  def self.render(editable_content, html_blocks, options = {})
    doc = Nokogiri::HTML(editable_content, nil, 'UTF-8')
    if options[:js_libs]
      head_elm = doc.xpath('/html/head')
      options[:js_libs].each do |libspec|
        if libspec.to_s =~ /_css$/
          head_elm.children.after <<EOL
<link rel="stylesheet" href="#{Static.send libspec}" type="text/css" media="all"/>
EOL
        else
          head_elm.children.after <<EOL
<script src="#{Static.send libspec}" type="text/javascript"/>
EOL
        end
      end
    end
    extract_ot_attributes doc
    xhtml_text = to_indented_xhtml doc
    xhtml_text = xhtml_text.gsub(/<one-table:(.+?)><\/one-table:(.+?)>/) do |match|
      html_blocks[$1]
    end
    xhtml_text.gsub!(/\b_(.+?)_\b/) do |match|
      keys = $1.split(/:/)
      hb = html_blocks[keys[0]]
      if hb
        hb.metadata[keys[1].to_sym]
      else
        match
      end
    end
    if options[:google_analytics]
      xhtml_text.gsub!(/<\/body>/i, <<EOL)
<script type="text/javascript">
<![CDATA[
  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', '#{options[:google_analytics]}']);
  _gaq.push(['_trackPageview']);
  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();
]]>
</script>
</body>
EOL
    end
    Nokogiri::HTML(xhtml_text, nil, 'UTF-8').to_s
  end

  def parse
    doc = Nokogiri::HTML(@page_content, nil, 'UTF-8')
    ot_blocks = {}
    doc.xpath('//*[@ot]').each do |ot|
      name = ot['ot'].split(/;/).first
      if name == '-' || ot_blocks[name]
        ot.remove
      else
        ot.remove_attribute 'ot'
        ot_blocks[name] = self.class.to_indented_xhtml(ot)
        ot.attributes.keys.each do |atkey|
          ot.delete atkey
        end
        ot['key'] = name
        ot.content = ''
        ot.name = 'ot'
      end
    end
    [self.class.to_indented_xhtml(doc), ot_blocks]
  end

  private
  def self.to_indented_xhtml(document)
    document.to_xhtml(:indent => 4, :encoding => 'UTF-8').gsub(/\&\#13;/, '').gsub(/_[^_]*(%[\dA-F]{2})+[^_]*_/) { |match| CGI.unescape match }
  end
  def self.extract_ot_attributes(doc)
    doc.xpath('//*[@ot]').each do |ot|
      name = ot['ot'].split(/;/).first
      if name == '-'
        ot.remove
      else
        ot.attributes.keys.each do |atkey|
          ot.delete atkey
        end
        ot.name = "one-table:#{name}"
        ot.inner_html = ''
      end
    end
  end

end
