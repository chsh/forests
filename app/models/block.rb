# encoding: UTF-8
class Block < ActiveRecord::Base
  attr_protected :user_id, :site_id
  has_many :block_contents, :dependent => :delete_all
  belongs_to :user
  belongs_to :one_table
  belongs_to :site
  has_many :block_one_table_headers, :order => 'sort_index', :dependent => :delete_all

  has_one :admin_option, :as => :attachable, :dependent => :delete

  accepts_nested_attributes_for :admin_option

  KINDS = [
          ['id', 1],
          ['list', 2],
#          ['form', 3],
          ['search_items', 4],
          ['display_items', 5],
          ['list_display_items', 6]
  ].freeze

  KIND_ID = 1
  KIND_LIST = 2
  KIND_FORM = 3
  KIND_SEARCH_ITEMS = 4
  KIND_DISPLAY_ITEMS = 5
  KIND_LIST_DISPLAY_ITEMS = 6

  ID2KINDS = Hash[*KINDS.flatten.reverse]

  def admin_options
    (self.admin_option ||= self.build_admin_option).attrs
  end

  def show_in_menu=(value)
    self.admin_options['show_in_menu'] = value ? true : false
  end
  def show_in_menu
    show_in_menu?
  end
  def show_in_menu?
    self.admin_options['show_in_menu'] ? true : false
  end

  def description=(value)
    admin_options['description'] = value
  end
  def description
    admin_options['description']
  end

  def render(params = {}, matches = {})
    case self.kind
    when KIND_SEARCH_ITEMS
      bsie = BlockSearchItemsExtractor.new(self)
      r = bsie.render(params, matches)
      @jquery_enabled = bsie.jquery_enabled
      r
    else render_default(params, matches)
    end
  end

  before_save :fill_user_and_admin_option
  def fill_user_and_admin_option
    if self[:site_id] && !self[:user_id]
      self[:user_id] = self.site(:select => 'user_id').user_id
    end
    (self.admin_option ||= self.build_admin_option).save
  end
  after_save :update_block_content_and_page_and_oth
  def update_block_content_and_page_and_oth
    if @content_type && @content
      block_content = self.block_contents.find_by_content_type @content_type
      unless block_content
        block_content = self.block_contents.build :content_type => @content_type
      end
      block_content.content = @content
      block_content.save
    end
    self.site.push_to_pages_from_block(self.name) if self.site_id
    save_block_one_table_headers
  end
  def block_items
    @block_items ||= SearchItems.new(self)
  end
  def search_items=(value)
    @editable_items_attrs = value
  end
  def search_items_raw=(value)
    sn2oths = self.one_table.one_table_headers.refmap(&:sysname).merge 'ht' => OneTableHeaderValue::FREEWORD_SEARCH
    v2 = {}
    value.each do |key, value|
      v2[sn2oths[key].id] = value
    end
    @editable_items_attrs = v2
  end
  def search_items_raw
    @editable_items_attrs_raw ||= block_items.editable_items_attrs_raw
  end
  def content_type=(value)
    @content_type = value
  end
  def content=(value)
    @content = value
  end
  def content_type
    @content_type ||= 'text/html'
  end
  def content
    @content ||= build_content
  end
  def build_content_for_rendering
    map = {}
    map = self.one_table.header_label_to_name_map if self.one_table
    c = render_display_items
    replace_keywords(c, map)
  end

  def refered_pages
    return [] if site.blank?
    @refered_pages ||= build_refered_pages
  end

  def required_js_libs
    if @jquery_enabled
      [:jquery, :jquery_ui, :jquery_ui_datepicker, :jquery_ui_css]
    else
      []
    end
  end

  private
  def build_refered_pages
    site.pages.map do |page|
      page if page.block_keys.include? self.name
    end.compact
  end
  def condition_map(params = {}, matches = {})
    ca = (self[:conditions] || '').gsub(/\s+/, '').split(/,/).map { |kv|
      kvp = kv.split(/=/)
      kvp[1] = (matches[kvp[0]] || params[kvp[0]]) if kvp[1] == '?'
      kvp
    }
    ca = Hash[*ca.flatten]
    ca.merge! matches
    paging_opts = nil
    query_opts = nil
    if params
      ca.merge!(header_name_params(params))
      if params['page']
        paging_opts = {}
        paging_opts[:limit] = (params['limit'] || 10).to_i
        paging_opts[:offset] =  paging_opts[:limit] * (params['page'].to_i - 1)
        query_opts = {}
        query_opts[:page] = params['page']
        query_opts[:em] = params['em'] if params['em']
      end
    end
    [ca, paging_opts, query_opts]
  end
  def header_name_params(params)
    ca = {}
    params.each do |key, value|
      if key =~ /^h(\d+|t)$/
        ca[key] = value
      end
    end
    ca
  end
  def render_default(params, matches)
    cm, paging_opts, query_opts = condition_map(params, matches)
    metadata = {}
    if self.one_table_id
      opts = {}
      if paging_opts
        opts = paging_opts
      else
        opts[:limit] = self.limit unless self.limit.blank?
      end
      opts[:order] = self[:order] unless self[:order].blank?
      recs = self.one_table.find_by_params cm, opts
      metadata[:rec_size] = recs.metadata[:rec_size]
      if metadata[:rec_size] == 0
        metadata[:rec_size_msg] = "1件も見つかりませんでした。"
      else
        metadata[:rec_size_msg] = "#{metadata[:rec_size]}件見つかりました。"
      end
      set_paging_values(metadata, paging_opts, cm, query_opts)
      if paging_opts
        if recs.size == 0
          metadata[:start_at] = 0
          metadata[:end_at] = 0
          metadata[:start_to_end] = ""
        else
          metadata[:start_at] = (paging_opts[:offset] || 0).to_i + 1
          metadata[:end_at] = (paging_opts[:offset] || 0).to_i + recs.size
          metadata[:start_to_end] = "#{metadata[:start_at]}件目から#{metadata[:end_at]}件目を表示しています。"
        end
      end
    else
      recs = nil
      metadata[:rec_size] = 0
    end
    MetaString.from render_with_content(recs, {:sort => horder }), metadata
  end

  def set_paging_values(metadata, paging_opts, std_conditions, query_opts)
    return unless paging_opts
    page = query_opts[:page]
    if metadata[:rec_size] > (paging_opts[:offset] + paging_opts[:limit])
      qs = qs_replace_pagenum page.to_i + 1, paging_opts, std_conditions, query_opts
      metadata[:next_page] = "<a href='?#{qs}'>次のページ</a>"
    else
      metadata[:next_page] = ""
    end
    if (paging_opts[:offset] - paging_opts[:limit]) >= 0
      qs = qs_replace_pagenum page.to_i - 1, paging_opts, std_conditions, query_opts
      metadata[:prev_page] = "<a href='?#{qs}'>前のページ</a>"
    else
      metadata[:prev_page] = ""
    end
  end

  def qs_replace_pagenum(page_num, paging_opts, std_conditions, query_opts)
    qp = {}
    qp['limit'] = paging_opts[:limit]
    qp['em'] = query_opts[:em] if query_opts[:em]
    qp['page'] = page_num
    qp.merge! std_conditions
    qp.to_query
  end

  def build_content
    bc = find_block_content
    bc.content if bc
  end
  def find_block_content
    return nil if self.new_record?
    self.block_contents.find_by_content_type self.content_type
  end
  def render_with_content(rec, opts = {})
    bc = build_content_for_rendering
    if self.kind == KIND_FORM
      @extractor = FormExtractor.from bc
    else
      @extractor ||= RepetitionExtractor.from bc
    end
    unless @extractor
      @extractor = StandardExtractor.from bc, content_type
    end
    @extractor.render(rec, opts)
  end
  def replace_keywords(content, map)
    content.gsub(/\b_([^_]+)_\b/) do |match|
      key = map[$1]
      if key
        "_" + key + "_"
      else
        match
      end
    end
  end
  def horder
    return nil if self.order.blank?
    return nil unless self.one_table
    fields = self.order.split(',').map do |fs|
      cs = fs.strip.split(/\s+/)
      [self.one_table.header_label_to_name_map[cs[0]], cs[1]].join(' ')
    end.join(',')
  end
  def save_block_one_table_headers
    return if @editable_items_attrs.blank?
    block_items.update_by @editable_items_attrs
  end
  def render_display_items
    boths = self.block_one_table_headers
    return self.content if boths.size == 0
    bsie = BlockSearchItemsExtractor.new(self)
    rc = bsie.render({})
    @jquery_enabled = bsie.jquery_enabled
    rc
  end
end
