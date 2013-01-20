class Page < ActiveRecord::Base
  belongs_to :site
#  attr_protected :site_id, :block_keys, :url_keys
  has_one :admin_option, :as => :attachable, :dependent => :delete

  def admin_options
    (self.admin_option ||= self.build_admin_option).attrs
  end

  def description=(value)
    admin_options['description'] = value
  end
  def description
    admin_options['description']
  end

  before_save :build_and_save_page_content
  def build_and_save_page_content
    extract_name_to_regexp self[:name] if self[:name]
    if self.changed.include?('editable_content')
      self[:internal_content], @html_blocks = PageBlockBuilder.parse(self[:editable_content])
      self[:block_keys] = array_to_tab_text @html_blocks.keys.sort
    else
      _, html_blocks = PageBlockBuilder.parse(self[:editable_content])
      updated = false
      self.block_keys.each do |block_key|
        block = self.site.blocks.find_by_name(block_key)
        if block
          # compare last updated time
          bc = block.send :find_block_content
          if (self.updated_at < bc.updated_at) || inner_text(html_blocks[block_key]).empty?
            html_blocks[block_key] = bc.content
            updated = true
          end
        else
          # deleted: restore from editable_content.
          @html_blocks ||= {}
          @html_blocks[block_key] = html_blocks[block_key]
        end
        self[:editable_content] = PageBlockBuilder.merge(self[:editable_content], html_blocks) if updated
      end
    end
    (self.admin_option ||= self.build_admin_option).save
  end

  after_save :update_html_blocks
  def update_html_blocks
    if @html_blocks
      @html_blocks.each do |name, html_block|
        block = self.site.blocks.find_by_name name
        if block
          push_to_block_if_updated_and_not_empty block, html_block
        else
          create_new_block name, html_block
        end
      end
    end
    self.site.last_updated_cache = self.updated_at
  end

  def match_hash(string)
    md = /#{self[:path_regexp]}/.match string
    if md
      vals = md[1, self.url_keys.size]
      Hash[*[self.url_keys, vals].transpose.flatten]
    end
  end

  def block_keys
    tab_text_to_array self[:block_keys]
  end

  def url_keys
    tab_text_to_array self[:url_keys]
  end

  def render_content(params = {}, matches = {})
    WordLogger.log(site, params) if keyword_logging?
    send("render_content_#{detect_render_type}", params, matches)
  end
  def render_content_pdf(params = {}, matches = {})
    kit = PDFKit.new(render_content_text(params, matches), page_size: 'A4')
    kit.to_pdf
  end
  def render_content_text(params = {}, matches = {})
    content = self.editable_content.gsub(/\b_site:(.+?)_\b/) do |match|
      key = $1
      sa = self.site.attrs_by_key[key]
      if sa
        sa.render_content(self.name)
      else
        "<span title=\"Key(#{key}) not found.\" style=\"color:red;font-weight:bold\">#{match}</span>"
      end
    end
    render_content_without_site_attributes(content, params, matches)
  end
  def render_content_ruby(params = {}, matches = {})
    eval self.editable_content
  end
  def render_content_without_site_attributes(content, params = {}, matches = {})
    opts = {}
    unless self.site.attrs['google_analytics_ua'].blank?
      opts[:google_analytics] = self.site.attrs['google_analytics_ua']
    end
    if self.block_keys.empty?
      if opts[:google_analytics]
        return PageBlockBuilder.render(content, {}, opts)
      else
        return content
      end
    end
    req_js_libs = []
    block_map = Hash[*self.block_keys.map do |block_key|
      block = self.site.blocks.find_by_name block_key
      r = [block_key, block.render(params, matches)]
      req_js_libs << block.required_js_libs
      r
    end.flatten]
    opts[:js_libs] = req_js_libs.flatten.compact.uniq
    PageBlockBuilder.render(content, block_map, opts)
  end

  private
  def extract_name_to_regexp(source)
    new_keys = []
    base = source.gsub /\b_(.+?)_\b/ do |matched|
      new_keys << $1
      '\b([^\/]+?)\b'
    end
    self[:path_regexp] = fix_regexp_begin_end base
    self[:url_keys] = array_to_tab_text new_keys
  end

  def fix_regexp_begin_end(string)
    "^#{string}$"
  end

  def editable_content_updated?
    @editable_content && (self[:editable_content] != @editable_content)
  end

  def push_to_block_if_updated_and_not_empty(block, html_block)
    return if block.updated_at >= self.updated_at
    return if block.content == html_block
    return if inner_text(html_block).empty?
    block.update_attribute :content, html_block
  end

  def create_new_block(name, html_block)
    self.site.blocks.create :name => name,
                            :content_type => 'text/html',
                            :content => html_block
  end

  def tab_text_to_array(source)
    source ||= ''
    source.split(/\t/)
  end

  def array_to_tab_text(array)
    array.join("\t")
  end

  def inner_text(text_content)
    Nokogiri::HTML.fragment(text_content).text
  end

  def detect_render_type
    return self.language.downcase unless self.language.blank?
    case self.name
    when /\.pdf$/i then 'pdf'
    when /\.rb$/i then 'ruby'
    else 'text'
    end
  end

end
