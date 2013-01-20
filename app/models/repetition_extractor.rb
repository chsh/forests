require 'nokogiri'

# 階層化された繰り返し要素を描画するレンダラ
class RepetitionExtractor
  attr_reader :root_text, :fragment_map
  def self.from(source)
    rex = new(source)
    return nil if rex.root_text.nil?
    rex
  end
  def initialize(*args)
    if args.size == 1 && args[0].is_a?(String)
      @root_text, @fragment_map = parse(args[0])
    elsif args.size == 2 && args[0].is_a?(String) && args[1].is_a?(Hash)
      @root_text = args[0]; @fragment_map = args[1]
    else raise "Error"
    end
  end

  def render(arg, opts = {})
    tr_opts = {:sort => opts[:sort]}
    render_source(@root_text, arg, tr_opts).flatten.join('')
  end

  private
  def render_source(key, arg, opts = {})
    if arg.is_a? Array
      return [''] if arg.size == 0
      arg = TableReader.from_hash_array arg
      arg = arg.sort(opts[:sort]) if opts[:sort]
      arg
    end
    render_source_tr(key, arg)
  end
  def render_source_tr(key, tr)
    raise "sub block:#{match} doesn't exist." unless @fragment_map[key]
    pkey = plain_key key
    vals = tr.distinct_values pkey
    fragment = @fragment_map[key]
    render_fragment fragment, pkey, vals, tr
  end
  def render_fragment(fragment, pkey, vals, tr)
    vals.map do |val|
      f = fragment.gsub(/\b_(.+?)_\b/) do |match|
        val.metadata[$1]
      end
      f.gsub(/(\[:.+?\:\])/) do |match|
        tr2 = tr.squeeze({pkey => val})
        render_source(match, tr2).flatten.join('')
      end
    end
  end
  def plain_key(text_key)
    text_key.gsub(/^\[:(.+)\:\]$/, '\1')
  end
  def parse(html_fragment)
    @doc = Nokogiri::HTML::fragment(html_fragment)
    elm = find_non_text_element(@doc)
    return nil unless elm
    return nil unless elm['repeat']
    fmap = {}
    text = parse_nodes(@doc.children, fmap)
    [text, fmap]
  end

  TAG_PREFIX = '[:'
  TAG_SUFFIX = ':]'

  def parse_nodes(nodes, fmap)
    nodes.map do |node|
      rep_name = node['repeat']
      if rep_name
        rep_name = rep_name.gsub(/^_/, '').gsub(/_$/, '')
        rep_name = "#{TAG_PREFIX}#{rep_name}#{TAG_SUFFIX}"
        fmap[rep_name] = eval_repeat_node(node, fmap)
        rep_name
      else
        textize_node node, parse_nodes(node.children, fmap)
      end
    end.join("\n")
  end
  def eval_repeat_node(node, fmap)
    node.remove_attribute 'repeat'
    inner_text = parse_nodes node.children, fmap
    textize_node(node, inner_text)
  end
  private
  def textize_node(node, inner_text)
    if node.text?
      node.serialize :encoding => 'UTF-8'
    elsif node.element?
      <<EOL
  <#{node.name}#{attrs_as_param(node)}>
  #{inner_text}
  </#{node.name}>
EOL
    end
  end
  def attrs_as_param(node)
    node.attribute_nodes.map { |xa| xa.serialize :encoding => 'UTF-8' }.join('')
  end
  def find_non_text_element(doc)
    doc.children.each do |node|
      return node unless node.class == Nokogiri::XML::Text
    end
    nil
  end
end
