
class Site < ActiveRecord::Base
  attr_protected :user_id
  has_many :pages, :dependent => :delete_all
  has_many :blocks
  belongs_to :user
  has_many :site_files, :order => 'path', :conditions => { :folder => false }, :dependent => :delete_all
  has_many :site_attributes, :order => 'key', :dependent => :delete_all

  attr_accessor :file, :source_site_id, :permission

  has_one :admin_option, :as => :attachable, :dependent => :delete

  has_many :logged_words
  has_many :search_activities

  has_many :permissions, as: :model,
           class_name: 'UserModelPermission'

  def self.enabled=(value)
    @@enabled = value
  end
  def self.enabled?
    false
#    @@enabled ? true : false
  end
  # EXTENSION:FORESTS: BEGIN
  def search_exportable?
    self.site_attributes.where(key: 'site_table_name').count > 0
  end
  def search_export(path, host)
    sah = site_attributes_hash.slice('site_table_name', 'university_name',
                                     'year', 'url_pattern').merge('path' => path)
    sah['url_pattern'] = "http://syl-web1.code.ouj.ac.jp/#{self.name}/#{sah['url_pattern'].gsub(/^\/+/, '')}"
    # verify table_name key.
    ot = self.user.one_tables.where(name: sah['site_table_name']).first
    ot.export_for_traversal_search(sah)
  end
  def site_attributes_hash
    Hash[*self.site_attributes.map do |sa|
      [sa.key, sa.value]
    end.flatten]
  end
  # EXTENSION:FORESTS: END

  def show_in_menu_blocks?
    self.blocks.each do |b|
      b.show_in_menu?
      return true
    end
    false
  end
  def show_in_menu_blocks
    self.blocks.select { |b| b.show_in_menu? }
  end
  def self.find_clonables
    Site.find_all_by_clonable true
  end

  def self.lookup_name_for_virtualhost(value)
    @@lookup_name_for_virtualhost_intervals ||= {}
    site = nil
    now = Time.now
    iv = @@lookup_name_for_virtualhost_intervals[value]
    if (iv && iv < now) || !iv
      site = Site.find_by_virtualhost(value)
      @@lookup_name_for_virtualhost_intervals[value] = now + eval((class_config['virtualhost_lookup_interval'] || '0'))
    end
    return nil unless site
    site.name
  end

  def source_from(site_id)
    self.source_site_id = site_id
    site = Site.find site_id
    self.name = site.name
    self.title = site.title
    self.description = site.description
  end

  def index_url
    "/#{self.name}/index.html"
  end
  def self.clonables
    self.find(:all, :conditions => { :clonable => true })
  end
  def admin_options
    (self.admin_option ||= self.build_admin_option).attrs
  end

  def description=(value)
    @description = admin_options['description'] = value
  end
  def description
    @description ||= admin_options['description']
  end

  def title=(value)
    admin_options[:title] = value
  end
  def title
    admin_options[:title]
  end

  def admin?(current_user)
    return false unless user
    user.id == current_user.id
  end

  before_save :fill_admin_option_if_empty
  def fill_admin_option_if_empty
    (self.admin_option ||= self.build_admin_option).save
  end

  before_update :save_name_changes
  def save_name_changes
    if changed.include? 'name'
      @name_before = changes['name'][0]
      @name_after = changes['name'][1]
      @name_changed = true
    end
  end

  after_update :adjust_mongo_key_using_name
  def adjust_mongo_key_using_name
    if @name_changed
      rename_mongo_key(@name_before, @name_after)
      # TODO: drop memcache data
      self.files.list_names.each do |name|
        RawMemCache.invalidate! "/#{@name_before}/#{name}"
      end
    end
  end

  def permitted?(user, action)
    self.permissions.send(action).include? user_id: user
  end
#  after_create :assign_permission
#  after_destroy :unassign_permission
#  def assign_permission
#    return unless self.user
#    self.user.permissions.assign editable: self
#  end
#  def unassign_permission
#    return unless self.user
#    self.user.permissions.unassign editable: self
#  end

  def rename_mongo_key(name_before, name_after)
    MongoFiles.rename(name_before, name_after)
  end

  def self.[](value)
    @@sites ||= {}
    @@sites[name] ||= self.find_by_name value
  end

  # hash reference of site_attributes.
  def attrs
    @attrs ||= SiteAttributes.new self
  end

  def attrs_by_key
    @attrs_by_key ||= self.site_attributes.refmap(&:key)
  end

  def self.find_recent(num_max)
    find(:all, :limit => num_max, :order => 'updated_at desc')
  end

  def push_to_pages_from_block(block_name)
    self.pages.each do |page|
      next unless page.block_keys.include? block_name
      page.save
    end
  end

  after_create :import_or_copy_files_if_exist
  def import_or_copy_files_if_exist
    if self.file
      self.import_files self.file
    elsif self.source_site_id.to_i > 0
      copy_from(Site.find(self.source_site_id))
    end
  end

  def copy_from(other_site)
    raise "Copy failed." if other_site.blank? || ((other_site.user_id != self.user_id) && !other_site.clonable)
    files.import other_site.files
    sync_files_and_site_files
    import_pages other_site
    import_site_attributes other_site
    import_one_tables other_site
    import_admin_option other_site
  end

  def one_tables
    one_tables_map = {}
    blocks.each do |block|
      one_tables_map[block.one_table] = 1 unless block.one_table.blank?
    end
    one_tables_map.keys
  end

  def files(force_reload = false)
    @files = nil if force_reload
    @files ||= MongoFiles.new(self.name, :exclude_patterns => mongo_files_exclude_patterns)
  end

  after_destroy :destroy_files
  def destroy_files
    self.files.destroy
  end

  def block_by_name(value)
    self.blocks.find_by_name value
  end

  def import_files(dir_or_zipfile, opts = {})
    opts.reverse_merge! :generate_pages => true
    files.import dir_or_zipfile
    sync_files_and_site_files
    create_pages_from_imported_files if opts[:generate_pages]
  end

  def regenerate_pages
    success = true
    begin
      create_pages_from_imported_files true
    rescue
      success = false
    end
    success
  end

  def html_path?(name)
    name.downcase =~ /\.html?$/
  end

  def matched_page(path)
    verify_modified_since
    @page_matchers ||= build_page_matchers
    @page_matchers.each do |matcher|
      result = matcher.match_hash(path)
      return [matcher, result] if result
    end
    # matching
    @page_by_name ||= build_page_by_name
    [@page_by_name[path], nil]
  end

  def refresh_page_cache
    @redis ||= ClassCache.for(self)
    @redis['pages']
  end

  # 1サイトが複数のサーバで構成されるようになった場合、それぞれのサーバが持つキャッシュを更新して回る必要がある。
  def last_updated_cache=(new_time)
    redis["#{self.id}:last_updated"] = new_time.to_i
  end
  private
  def redis
    @redis ||= ClassCache.for(self)
  end
  def verify_modified_since
    lup = (redis["#{self.id}:last_updated"] ||= self.updated_at.to_i).to_i
    if lup > self.updated_at.to_i
      self.updated_at = Time.at(lup)
      self.pages(true)
      @page_matchers = nil
      @page_by_name = nil
      redis["#{self.id}:last_updated"] = self.updated_at.to_i
    end
  end
  def import_pages(other_site)
    other_site.pages.each do |page|
      self.pages.create page.attributes
    end
  end
  def build_page_matchers
    self.pages.map { |page| page unless page.path_regexp.blank? }.compact.sort { |a, b| a.url_keys.size <=> b.url_keys.size }
  end
  def build_page_by_name
    Hash[*self.pages.map { |page| [page.name, page] }.flatten]
  end
  def reset_blocks_by(ot_blocks)
    Site.transaction do
      name_block_map = self.blocks.refmap(&:name)
      ot_blocks.each do |name, content|
        block = name_block_map[name]
        if block
          block.update_attribute :content, content
        else
          self.blocks.create :sysname => name, :content => content,
                             :format => 'text/html',
                             :user_id => self.user_id
        end
      end
    end
  end

  def create_pages_from_imported_files(clear_pages = true)
    html_paths = []
    files.list_names.each do |name|
      html_paths << name if html_path?(name)
    end
    Site.transaction do
      self.pages.clear
      html_paths.each do |html_path|
        self.pages.create :name => html_path,
                          :editable_content => files.content(html_path),
                          :published => false
      end
    end
  end

  def import_one_tables(other_site)
    ary = other_site.blocks.map { |b| [b.name, b.one_table_id]}
    bn2b = other_site.blocks.refmap(&:name)
    bn2ot = Hash[*ary.flatten]
    n2b = self.blocks.refmap(&:name)
    oot2ot = {}
    n2b.each do |name, block|
      otsrc = bn2ot[name]
      bsrc = bn2b[name]
      if otsrc
        otid = oot2ot[otsrc]
        unless otid
          otid = OneTable.find(otsrc).copy_instance :user_id => self.user_id
          oot2ot[otsrc] = otid
        end
        ats = remove_active_record_specific_attrs bsrc, 'one_table_id', 'site_id', 'user_id'
        block.update_attributes ats.merge('one_table_id' => otid.id)
        block.update_attributes 'search_items_raw' => bsrc.search_items_raw
      end
    end
  end

  def import_admin_option(other_site)
    self.admin_option.attrs = other_site.admin_option.attrs.merge(self.admin_option.attrs)
    self.admin_option.save
  end
  def remove_active_record_specific_attrs(ar, *other_keys)
    other_keys = [other_keys].flatten
    ats = ar.attributes.clone
    ats.delete 'id'
    ats.delete 'created_at'
    ats.delete 'updated_at'
    other_keys.each do |other_key|
      ats.delete other_key
    end
    ats
  end
  def sync_files_and_site_files
    self.files.list_names.each do |path|
      unless self.site_files.find_by_path(path)
        self.site_files.create :path => path
      end
    end
  end
  def mongo_files_exclude_patterns
    (self.class.class_config.exclude_patterns || []).map do |ep|
      /#{ep}/
    end
  end
  def import_site_attributes(other_site)
    Site.transaction do
      self.site_attributes.clear
      other_site.site_attributes.each do |sa|
        SiteAttribute.create sa.attributes_for_new_instance.merge(:site_id => self.id)
      end
    end
  end
  def self.build_virtualhost_to_site_map
    sites = self.all :conditions => 'virtualhost is not null',
             :select => 'id, virtualhost, name, updated_at',
             :order => 'updated_at desc'

  end
end
