# encoding: UTF-8

require 'csv'
require 'nkf'
require 'shoji'

class NewHeader
  def initialize(attrs = {})
    @attrs = attrs
  end
  def label; refer :label; end
  def label=(value); alter :label, value; end
  def kind; refer :kind; end
  def kind=(value); alter :kind, value; end
  def index; refer :index; end
  def index=(value); alter :index, value; end

  private
  def alter(key, value)
    @attrs[key] = value
  end
  def refer(key)
    @attrs[key]
  end
end

class OneTable < ActiveRecord::Base
  resourcify
#  belongs_to :mongo_connection
#  belongs_to :solr_connection
#  belongs_to :media_keeper, :class_name => 'MongoConnection'
  belongs_to :user
  has_many :one_table_headers, :order => 'index', :dependent => :delete_all
  has_many :blocks, :dependent => :delete_all
  has_one :template_file, :class_name => 'MongoAttachment', :as => :attachable,
          :conditions => { :filename => 'template.xls' }
  has_one :last_error, :class_name => 'ExceptionKeeper', :as => :keepable
  has_one :traversal_search_option, dependent: :delete
  has_many :hooks, dependent: :delete_all, class_name: 'OneTableHook'

  has_many :permissions, as: :model,
           class_name: 'UserModelPermission',
           dependent: :delete_all

  has_many :one_table_templates
  has_many :activities

  scope :is_public, where(is_public: true)

  attr_accessor :permission

  def one_table_template_creatable?
    self.one_table_headers.primary_key_present.count > 0
  end
  def permitted?(user, action)
    self.permissions.send(action).include? user_id: user
  end

  def mongo_connection
    MongoConnection.default
  end
  def solr_connection
    SolrConnection.default
  end
  def media_keeper
    MongoConnection.media_keeper
  end
  # EXTENSION:FORESTS: BEGIN
  def export_for_traversal_search(opts)
    url_key = nil
    url_builder = opts['url_pattern'].gsub(/_(.+?)_/) do |match|
      url_key = $1
      '_#%<<_#%<<_#%<<_'
    end
    targets = {}
    one_table_headers.each do |oth|
      targets['department'] = oth if oth.metadata['department']
      targets['course'] = oth if oth.metadata['course']
      targets['title'] = oth if oth.metadata['title']
      targets['description'] = oth if oth.metadata['description']
      targets['url_key'] = oth if oth.refname == url_key || oth.label == url_key
    end
    targets['url_key'] = 'ID' if url_key == 'ID'
    tsv_file = "ot#{self.id}.tsv"
    yml_file = "ot#{self.id}.yml"
    File.open(tsv_file, 'w') do |w|
      self.records.each do |rec|
        row = {}
        targets.each do |key, header|
          if key == 'url_key'
            if header == 'ID'
              row['url'] = url_builder.gsub('_#%<<_#%<<_#%<<_', rec.id)
            else
              row['url'] = url_builder.gsub('_#%<<_#%<<_#%<<_', rec[header.sysname])
            end
          else
            row[key] = rec[header.sysname].to_s.strip.gsub(/\s+/, ' ')
          end
        end
        r = ['department', 'course', 'title', 'description', 'url'].map do |key|
          row[key].to_s
        end.join("\t")
        w.puts r
      end
    end
    File.open(yml_file, 'w') do |w|
      h = {
          fields_map: {
              university: opts['university_name'],
              department: 0, course: 1, title: 2, desc: 3,
              year: opts['year']
          },
          url_format: {
              pattern: "[4]"
          }
      }
      w.puts h.to_yaml
    end
    system("zip -r #{opts['path']} #{tsv_file} #{yml_file}")
  end
  # EXTENSION:FORESTS: END

  before_save :fill_empty_values
  def fill_empty_values
    if @mongo_attachment
      self.name = @mongo_attachment.metadata[:filename] if self.name.blank?
      self.status = 'preparing-to-import'
    end
  end
  after_create :import_attachment_and_oth #, :assign_permission
  def import_attachment_and_oth
    if @mongo_attachment
      @mongo_attachment.user_id = self.user_id
      @mongo_attachment.save
      self.import @mongo_attachment.id, true
    end
    if @other_one_table_headers
      self.one_table_headers = @other_one_table_headers
    end
  end
#  after_destroy :unassign_permission
#  def assign_permission
#    return unless self.user
#    self.user.permissions.assign editable: self
#  end
#  def unassign_permission
#    return unless self.user
#    self.user.permissions.unassign editable: self
#  end
  after_save :save_template
  def save_template
    if @template_file
      ma = MongoAttachment.find_by_attachable_type_and_attachable_id_and_filename 'OneTable', self.id, 'template.xls'
      ma.destroy if ma
      @template_file.filename = 'template.xls'
      @template_file.attachable_type = 'OneTable'
      @template_file.attachable_id = self.id
      @template_file.user_id = self.user_id
      @template_file.save!
    end
  end

  def file_filter(params)
    new_params = {}
    params.each do |k, v|
      oth = label_to_header[k]
      if oth.file_field?
        new_params[k] = save_media(oth, v)
      else
        new_params[k] = v
      end
    end
    new_params
  end
  def file_fields?
    if @has_file_fields.nil?
      @has_file_fields = has_file_fields
    end
    @has_file_fields
  end
  def export(output = STDOUT, opts = {})
    xml = Exporter::XML.new.export(self.one_table_headers, self.rows)
    if output.is_a? String
      File.open(output, 'w') do |f|
        f.write xml
      end
    elsif output.is_a? IO
      f.write xml
    end
  end

  def copy_instance(overridden_attributes = {}, background = true)
    ot = nil
    OneTable.transaction do
      new_name = copied_unique_name(name)
      ats = {
              :user_id => self.user_id,
              :one_table_headers_from => self,
              :name => "#{new_name}"
      }.merge(overridden_attributes)
      ot = OneTable.create ats
      ot.update_attributes :template_file => self.template_file if self.template_file
      self.one_table_headers.each_with_index do |oth, index|
        next unless oth.model_comment
        ot.one_table_headers[index].update_attributes :model_comment => oth.model_comment
      end
      ot.send :copy_one_table_templates_from, self
    end
    ot.tap { |obj| obj.import(self, background) }
  end

  def one_table_header_map
    @one_table_header_map ||= build_one_table_header_map
  end

  def one_table_headers_from=(other)
    @other_one_table_headers = other.one_table_headers.map { |oth| oth.new_instance }
  end

  def sites
    sites_map = {}
    blocks.map do |block|
      sites_map[block.site] = 1 if block.site
    end
    sites_map.keys
  end

  def self.find_recent(num_max)
    find(:all, :limit => num_max, :order => 'updated_at desc')
  end

  def self.find_permitted(one_table_id, user, action)
    ot = self.find one_table_id
    uad = ot.user_accessible_datas.find_by_user_id(user.id, :select =>'id, permission_bits')
    return ot if (uad && uad.permitted?(action))
  end

  def self.background_import=(flag)
    @@background_import = flag ? true : false
  end
  def self.background_import
    @@background_import
  end
  def import_uploaded(filename, options = {})
    mid = create_attachment filename
    import(mid.id, true, options)
  end
  def import(filename, background = false, options = {})
    update_status 'preparing-to-import'
    if background
      self.delay.execute_import filename, options
    else
      self.execute_import filename, options
    end
  end

  def reset_status
    update_attributes :status => nil
  end
  def status(reload = false)
    if reload
      @status = self.class.find(self.id, :select => 'status').status
    else
      @status ||= self[:status]
    end
  end

  def fill_virtual_field(one_table_header_ids, background = false)
    if background
      update_attributes :status => 'preparing-to-create-virtual-field'
      self.delay.execute_fill_virtual_field one_table_header_ids
    else
      self.execute_fill_virtual_field one_table_header_ids
    end
  end

  def execute_fill_virtual_field(one_table_header_ids = [])
    update_attributes :status => 'creating-virtual-field'
    self.row_ids.each do |row_id|
      otr = self.record row_id
      otr.update_attributes({}, {}, {run_aftersave_hooks: false})
    end
    reset_status
  end

  def create_attachment(value)
    self.user.create_attachment value
  end

  def file
    @file
  end
  def file=(value)
    @mongo_attachment = MongoAttachment.new :file => value
  end
  def template_file=(value)
    # TODO: copy MongoAttachment directly.
    value = value.tempfile.path if value.is_a? MongoAttachment
    @template_file = MongoAttachment.new :file => value
  end

  attr_accessor :namemap
  def one_table_headers_with_namemap
    oths = one_table_headers
    if self.namemap.present?
      oths.each do |oth|
        if namemap[oth.label].present?
          oth.label = namemap[oth.label]
        end
      end
    end
    oths
  end

  def execute_import(filename_or_mongo_attachment_id, options = {})
    provide_filename(filename_or_mongo_attachment_id) do |filename|
      if options[:do_delete]
        execute_deletion_by_filename(filename, options)
      else
        execute_import_by_filename(filename, options)
      end
    end
  end

  def clear_last_error
    self.last_error.destroy if self.last_error
  end

  def rows_with_headers(new_rows, new_headers, options = {})
#    clear_mongo_and_solr_documents
    cur_index = nil
    cur_new_row = nil
    sr = nil
    begin
      new_rows.each_with_index do |new_row, index|
        cur_new_row = new_row
        cur_index = index
        sr = save_mongo_and_solr(new_row, new_headers, options)
      end
      scon.commit
    rescue => e
      scon.rollback
      raise "Insert error at #{cur_index} for #{cur_new_row.inspect}. sr:#{sr.inspect} Source: #{e}"
    end
  end
  # replace all rows
  def rows=(new_rows)
#    clear_mongo_and_solr_documents
    cur_index = nil
    cur_new_row = nil
    sr = nil
    begin
      CopyDownImportHook.convert(new_rows).each_with_index do |new_row, index|
        cur_new_row = new_row
        cur_index = index
        sr = save_mongo_and_solr(new_row)
      end
      scon.commit
    rescue => e
      scon.rollback
      raise "Insert error at #{cur_index} for #{cur_new_row.inspect}. sr:#{sr.inspect} Source: #{e}"
    end
    run_hooks('after:save', last_modified: Time.now)
  end
  def rows(opts = {})
    qopts = { sort: '_id' }
    qopts[:limit] = opts[:limit] if opts[:limit]
    qopts[:skip] = opts[:offset] if opts[:offset]
    arrayze_hash mcol.find({}, qopts).to_a, :with_id => opts[:with_id]
  end
  def row_ids
    mcol.find({}, :sort => '_id', :fields => '_id').to_a.map { |rec| rec['_id'] }
  end
  def row_size
    mcol.count
  end
  def find_first
    mcol.find({}, limit: 1).first
  end
  def row_at(index, opts = {})
    itemize_hash mcol.find_one('_id' => bson_object_id(index)), :with_id => opts[:with_id]
  end
  def record(index = nil)
    if index
      mongo_id = bson_object_id index
      rec = mcol.find_one('_id' => mongo_id)
      rec = header_filter(rec).merge '_id' => mongo_id
      OneTableRecord.from rec, self
    else
      OneTableRecord.from nil, self
    end
  end
  def records
    self.row_ids.map { |rid| self.record rid }
  end
  def destroy_rows(*row_ids)
    row_ids = [row_ids].flatten
    row_ids.each do |row_id|
      mcol.remove('_id' => bson_object_id(row_id))
      scon.delete_by_query "dom_ks:#{sid} AND dom_ki:#{row_id}"
    end
    scon.commit
    run_hooks 'after:save', last_modified: Time.now
  end
  def destroy_row(row_id)
    destroy_rows row_id
  end

  def headers=(new_headers)
    replace_headers new_headers
  end
  def append_headers(new_headers)
    OneTable.transaction do
      sz_oth = one_table_headers.size
      # lookup dest headers
      l2oth_map = one_table_headers.refmap(&:label)
      moidx = max_oth_index(one_table_headers)
      new_headers = regulate_new_headers(new_headers).refmap(&:label)
      oths4r = oths_for_remove l2oth_map, new_headers
      oths4k = oths_for_keep l2oth_map, new_headers
      nhs4n = nhs_for_new l2oth_map, new_headers
#      remove_oths_for_remove oths4r
#      update_oths_for_keep_index oths4k, new_headers
      create_oths_from_nhs_for_new nhs4n, moidx, sz_oth
    end
    # reload by index.
    one_table_headers(true)
  end
  def replace_headers(new_headers)
    OneTable.transaction do
      # lookup dest headers
      l2oth_map = one_table_headers.refmap(&:label)
      moidx = max_oth_index(one_table_headers)
      new_headers = regulate_new_headers(new_headers).refmap(&:label)
      oths4r = oths_for_remove l2oth_map, new_headers
      oths4k = oths_for_keep l2oth_map, new_headers
      nhs4n = nhs_for_new l2oth_map, new_headers
      remove_oths_for_remove oths4r
      regulate_oths_indexes
      sz_oth = one_table_headers.size
      create_oths_from_nhs_for_new nhs4n, moidx, sz_oth
    end
    # reload by index.
    one_table_headers(true)
  end
  def regulate_oths_indexes
    oths = one_table_headers(true)
    oths.each_with_index do |oth, index|
      oth.update_attributes :index => index
    end
  end
  def create_virtual_field(params)
    params.assert_valid_keys :label, :refname, :formula
    headers.create params
  end
  def header_label_and_types(refresh = false)
    one_table_headers(refresh).map do |h|
      [h.label, OneTableHeader::KIND2SYM_MAP[h.kind]]
    end
  end
  def header_labels(refresh = false)
    one_table_headers(refresh).map(&:label)
  end
  def header_names(refresh = false)
    one_table_headers(refresh).map(&:sysname)
  end
  def header_names_by_labels_or_refnames(*labels)
    [labels].flatten.map { |label| header_label_to_name_map[label] }
  end
  def header_filter(rec, refresh = false)
    rec ||= {}
    oh = BSON::OrderedHash.new
    one_table_headers(refresh).each { |h| oh[h.sysname] = rec[h.sysname] }
    oh
  end
  def header_label_to_name_map
    @header_label_to_name_map ||= Hash[*self.one_table_headers.map { |oth|
      base = [oth.label, oth.sysname]
      base += [oth.refname, oth.sysname] unless oth.refname.blank?
      base
    }.flatten]
  end

  def find(arg, opts = {})
    c = mcol
    case arg
    when Hash then q = hash_to_solr_query(arg)
    when String then q = string_to_solr_query(arg)
    end
    solrq = ["dom_ks:#{sid}", q].join(' ')
#    puts "solrq:#{solrq}"
    select_params = (opts[:solr] || {}).merge(:q => solrq)
    r = scon.post 'select', :data => select_params

    arrayze_hash(r.path('/response/docs').map { |hit| c.find_one('_id' => bson_object_id(hit['dom_ki'])) }, :with_id => opts[:with_id], :total_hits => r.path('/response/numFound'))
  end
  def find_by_params(params, opts = {})
    c = mcol
    if params.keys.include? 'ID'
      MetaArray.from([c.find_one('_id' => bson_object_id(params['ID']))],
                     :rec_size => 1)
    else
      q = hash_to_solr_query params
      qopts = { :rows => (opts[:limit] || 1000).to_i, :start => (opts[:offset] || 0).to_i }
      qs = ["dom_ks:#{sid}", q].join(' ')
      qopts[:sort] = solr_order(opts[:order]) if opts[:order]
      select_params = qopts.merge(:q => qs)
      r = scon.post 'select', :data => select_params
      metaopts = {:rec_size => r.path('/response/numFound')}
      MetaArray.from(r.path('/response/docs').map { |hit| c.find_one('_id' => bson_object_id(hit['dom_ki'])) },
                     metaopts)
    end
  end
  def rebuild_solr_index!
    reset_headers
    mcol.find.each do |doc|
#      puts doc.inspect
      index, hash = split_index_from_mongo_doc doc
      puts "index:#{index.inspect}, hash:#{hash.inspect}"
      srec = headers.solr_record(hash, self, index)
      puts "solr_rec:#{srec.inspect}"
      scon.add srec
    end
    scon.commit
  end

  def distinct_values(sysname, force_reload = false)
    value = nil
    KVStore.open('OneTable') do |kvs|
      if force_reload && kvs["OneTable:#{self.id}:#{sysname}"]
        kvs["OneTable:#{self.id}:#{sysname}"] = nil
      end
      value = (kvs["OneTable:#{self.id}:#{sysname}"] ||= build_distinct_values(sysname))
    end
    value
  end

  def content_for(format, opts = {})
    m = "content_for_#{format}"
    self.send(m, opts) if respond_to?(m)
  end

  def content_for_csv(opts = {})
    str = CSV.generate('', {}) do |csv|
      indexes = []
      if opts[:fields]
        key2idx = {}
        self.one_table_headers.each_with_index do |oth, index|
          key2idx[oth.label] = index unless oth.label.blank?
          key2idx[oth.sysname] = index unless oth.sysname.blank?
          key2idx[oth.refname] = index unless oth.refname.blank?
        end
        indexes = opts[:fields].map { |key| key2idx[key] }.compact
      else
        indexes = (0..self.one_table_headers.size-1).to_a
      end
      unless opts[:no_headers]
        csv << indexes.map { |idx| self.one_table_headers[idx].label }
      end
      self.rows.each do |row|
        csv << indexes.map { |idx| row[idx] }
      end
    end
    if opts[:target].to_s.downcase == 'windows'
      NKF.nkf('-Ws', str.gsub(/\r\n/, "\n").gsub(/\n/, "\r\n"))
    else
      str
    end
  end

  def content_for_tsv(opts = {})
    str = CSV.generate('', {col_sep: "\t"}) do |csv|
      csv << self.one_table_headers.map(&:label)
      self.rows.each do |row|
        csv << row
      end
    end
    if opts[:target].to_s.downcase == 'windows'
      str.gsub(/\r\n/, "\n").gsub(/\n/, "\r\n").encode('CP932')
    else
      str
    end
  end

  def clear_mongo_and_solr_documents(opts = {})
    key = KeyIdentifier.solr_collection_query(self.id)
    scon.delete_by_query key
    raise "Failed to remove solr documents. query pattern: '#{key}')" unless scon.commit
    raise "Failed to drop mongo collection('#{sid}')" unless mcol.drop
  end

  private
  def run_hooks(activity, opt_params = {})
    self.hooks.where(on: activity).each do |hook|
      hook.execute({one_table: self}.merge(opt_params))
    end
  end

  def csvopts_with(opts, additional_opts = {})
    csvopts = {}
    if opts[:windows]
      csvopts[:row_sep] = "\r\n"
    end
    csvopts.merge(additional_opts)
  end
  def build_distinct_values(sysname)
    mcol.distinct(sysname).compact.sort
  end
  def headers
    @one_table_headers_manager ||= OneTableHeaders.new(self, one_table_headers_with_namemap)
  end
  def save_mongo_and_solr(new_row, new_headers = nil, options = {})
    h = file_filter headers.hash_row(new_row, new_headers)
    save_mongo_and_solr_by_hash(h, nil, options.merge(:solr_commit => false))
  end
  def save_mongo_and_solr_by_hash(hash, index = nil, options = {})
    options.reverse_merge! :solr_commit => true, :ignore_primary_keys => false
    if index.nil? && !options[:ignore_primary_keys]
      keys_hash = extract_keys_hash(hash)
      if keys_hash.present?
        f = mcol.find(keys_hash)
        if f.count > 1
          logger.warn "Ignore hash:#{hash} contains primary keys but unique."
        elsif f.count == 1
          r = f.first
          index = r.delete('_id')
          hash.reverse_merge!(r)
        end
      end
    end
    hash = extract_meta_string_in_value(hash)
    index = save_mongo(hash, index)
    srec = headers.solr_record(hash, self, index)
    scon.add srec
    scon.commit if options[:solr_commit]
    index
  end
  def solr_commit
    scon.commit
  end
  def save_mongo(hash, index)
    if index
      mcol.save hash.merge('_id' => bson_object_id(index))
    else
      mcol.save hash.clone
    end
  end
  def provide_filename(filename_or_mongo_attachment_id)
    case filename_or_mongo_attachment_id
    when OneTable
      yield filename_or_mongo_attachment_id
    when Numeric
      tf = MongoAttachment.find(filename_or_mongo_attachment_id).tempfile
      yield tf.path
      tf.close true
    else
      yield filename_or_mongo_attachment_id
    end
  end
  def arrayze_hash(array, opts = {})
    ary = array.map do |item|
      itemize_hash(item, opts)
    end
    MetaArray.from ary, total_hits: opts[:total_hits]
  end
  def itemize_hash(row, opts = {})
    aid = row.delete '_id'
    cells = self.header_names.map { |hn| row[hn] }
    if opts[:with_id]
      {:cells => cells, :id => aid }
    else
      cells
    end
  end
  def hash_to_solr_query(hash)
    r = []
    hash.each do |key, value|
      skey = key.to_s
      svalue = value.to_s
      next if svalue.empty?
      if skey == 'ht'
        r << svalue
      else
        header = label_to_header[skey]
        r << solr_query_from_header(header, value)
      end
    end
    r.join ' '
  end
  ASCDESC_MAP = {
          'asc' => :ascending,
          'desc' => :descending
  }
  def solr_order(order_string)
    order_string.strip.split(/\s*,\s*/).map do |os|
      ws = os.strip.split(/\s+/)
      ws[1] = 'asc' if ws[1].blank?
      header = label_to_header[ws[0]]
      ws[0] = "#{header.sysname}_#{header.suffix}"
      [ ws[0], ws[1]].join(' ')
    end.join(', ')
  end
  def string_to_solr_query(query)
    rq = query.split(//).map { |ch| ch = ' ' if ch == '　'; ch }.join('')
    words = rq.strip.split(/\s+/)
    h = {}
    hts = []
    words.each do |w|
      if w =~ /^(.+?):(.+)$/
        h[$1] = $2
      else
        hts << w
      end
    end
    h['ht'] = hts.join(' ')
#    puts "h:#{h.inspect}"
    hash_to_solr_query h
  end

  def solr_query_from_header(header, value)
    case header.kind
    when OneTableHeader::KIND_DATE
      if value.is_a?(Hash) && (value['f'] || value['t'] || value['wd'])
        dt_params = []
        dt_from = solr_date_range_string(value['f'])
        dt_to = solr_date_range_string(value['t'])
        dt_params << "#{header.sysname}_#{header.suffix}:[#{dt_from} TO #{dt_to}]" unless (dt_from == '*' && dt_to == '*')
        unless value['wd'].blank?
          dt_params << "#{header.sysname}_wday_i:(#{value['wd'].join(' OR ')})"
        end
        dt_params.join(' ')
      else
        today = solr_date_range_string(value)
        "#{header.sysname}_#{header.suffix}:[#{today} TO #{today}]"
      end
    when OneTableHeader::KIND_INCLUDE_STRING
      values = ArrayConverter.partial_list [value].flatten
      value = '(' + values.join(' OR ') + ')'
      "#{header.sysname}_#{header.suffix}:#{value}"
    else
      if value.is_a? Array
        value = '(' + value.join(' OR ') + ')'
      end
      "#{header.sysname}_#{header.suffix}#{header.send(:mc)}:#{value}"
    end
  end

  def label_to_header
    @label_to_header ||= build_label_to_header
  end
  def label_to_sysname
    @label_to_sysname ||= build_label_to_sysname
  end
  def build_label_to_sysname
    Hash[*label_to_header.map do |key, header|
      [key, header.sysname]
    end.flatten]
  end
  def build_label_to_header
    h = {}
    one_table_headers.each do |header|
      h[header.label] = header
      h[header.sysname] = header
      h[header.refname] = header unless header.refname.blank?
    end
    h
  end
  def name_to_header(name)
    @name_to_header ||= build_name_to_header
    @name_to_header[name]
  end
  def build_name_to_header
    h = {}
    one_table_headers.each do |header|
      h[header.sysname] = header
    end
    h
  end
  def sid
    KeyIdentifier.one_table_key self.id
  end
  def mcon
    @mcon ||= mongo_connection.remote_connection
  end
  def mcol
    @mcol ||= mcon.collection sid
  end
  def scon
    @scon ||= solr_connection.remote_connection
  end
  def reset_mongo_and_solr_documents
    raise "Failed to reset solr documents." unless scon.rollback
    raise "Failed to drop mongo collection('#{sid}')" unless mcol.drop
  end
  def bson_object_id(value)
    bson_object_id_as_bson(value)
  end
  def bson_object_id_as_string(value)
    case value
    when BSON::ObjectId then value.to_s
    else value.to_s
    end
  end
  def bson_object_id_as_bson(value)
    case value
    when BSON::ObjectId then value
    when String then BSON::ObjectId.from_string value
    else raise "Unexpected value.class=#{value.class}"
    end
  end

  def find_with_id(*args)
    find args[0], :with_id => true
  end

  def split_index_from_mongo_doc(doc)
    doc = doc.clone
    index = doc.delete '_id'
    [index.to_s, doc]
  end

  def reset_headers
    self.one_table_headers true
    @name_to_header = nil
    @label_to_header = nil
    @one_table_headers_manager = nil
  end

  def regulate_date_param(param)
    if param.is_a? String
      param
    elsif param.is_a?(Hash)
      if param['y'].blank? && param['m'].blank? && param['d'].blank?
        nil
      else
        "#{param['y']}/#{param['m']}/#{param['d']}"
      end
    end
  end
  def solr_date_range_string(value)
    iso8601(regulate_date_param(value)) || '*'
  end
  def iso8601(value)
    return nil if value.blank?
    Time.parse(value).utc.iso8601
  end
  def regulate_new_headers(new_headers)
    index = 0
    new_headers.map do |nh|
      label = nh; sym = nil
      if nh.is_a? Array
        label = nh[0]
        sym = (nh[1] ||= :string)
      else
        sym = :text
      end
      kind = OneTableHeader::SYM2KIND_MAP[sym.to_sym]
      attrs = {:label => label, :kind => kind, :index => index}
      nh = NewHeader.new attrs
      index += 1
      nh
    end
  end
  def oths_for_remove(l2oth_map, new_headers)
    oth4r = {}
    l2oth_map.each do |label, oth|
      unless new_headers[label]
        oth4r[label] = oth
      end
    end
    oth4r
  end
  def oths_for_keep(l2oth_map, new_headers)
    oth4k = {}
    l2oth_map.each do |label, oth|
      oth4k[label] = oth if new_headers[label]
    end
    oth4k
  end
  def nhs_for_new(l2oth_map, new_headers)
    nhs4n = {}
    new_headers.each do |label, nh|
      nhs4n[label] = nh unless l2oth_map[label]
    end
    nhs4n
  end
  def max_oth_index(oths)
    return -1 if oths.size == 0
    moidx = -1
    oths.each do |oth|
      hidx = oth.sysname.gsub(/^h/, '').to_i
      moidx = hidx if moidx < hidx
    end
    moidx
  end
  def remove_oths_for_remove(oths4r)
    oths4r.each { |label, oth| oth.destroy }
  end
  def update_oths_for_keep_index(oths4k, new_headers)
    oths4k.each do |label, oth|
      nh = new_headers[label]
      oth.update_attributes :index => nh.index unless oth.index == nh.index
    end
  end
  def create_oths_from_nhs_for_new(nhs4n, moidx, index_base)
    nhs4n.values.sort do |a, b|
      a.index <=> b.index
    end.each_with_index do |nh, index|
      h = { :label => nh.label,
        :sysname => "h#{moidx + 1}", :index => index_base + index,
        :kind => nh.kind
      }
      moidx += 1
      one_table_headers.create h
    end
  end
  NEW_NAME_SUFFIXES = ['', (1 .. 99).to_a.map {|i| " (#{i})"}].flatten
  def copied_unique_name(name)
    for sfx in NEW_NAME_SUFFIXES
      new_name = "#{name.gsub(/ \(\d+\)$/, '')}#{sfx}"
      ot = self.user.one_tables.find_by_name new_name
      return new_name unless ot
    end
    raise "Can't set new name using (1)..(99)."
  end
  def update_status(status)
    self.update_attributes :status => status
  end
  def save_exception(e)
    le = self.last_error
    le = self.build_last_error unless le
    le.exception = e
    le.save
  end
  def has_file_fields
    self.one_table_headers.each do |oth|
      return true if oth.file_field?
    end
    false
  end
  def save_media(one_table_header, value)
    @media_keeper ||= MongoFiles.new("ot#{self.id}", :db => self.media_keeper)
    return unless one_table_header.kind_as_string == 'Image'
    ufs = UploadedFileOrString.new(value)
    path = nil
    loop do
      path = "#{SecureRandom.hex(20)}#{ufs.extname}"
      break unless @media_keeper.exist?(path)
    end
    @media_keeper.save path, ufs
    attrs = MagickCommand.size(@media_keeper.content(path))
    attrs.merge! :id => self.id
    MetaString.from(path,  attrs)
  end
  def extract_meta_string_in_value(hash)
    new_hash = {}
    hash.each do |k, v|
      if v.is_a? MetaString
        new_hash[k] = {
            'value' => v,
            'metadata' => v.metadata,
        }
      else
        new_hash[k] = v
      end
    end
    new_hash
  end
  def lbl2oth_with_namemap(oths, namemap)
    l2o_map = oths.refmap(&:label)
    return l2o_map if namemap.blank?
    namemap.each do |org, dst|
      value = l2o_map.delete(org)
      l2o_map[dst] = value
    end
    l2o_map
  end
  def extract_keys_hash(hash)
    headers.primary_keys_from_hash hash
  end
  def build_one_table_header_map
    ary = self.one_table_headers.map { |oth| [oth.sysname, oth] }
    Hash[*ary.flatten]
  end

  def copy_one_table_templates_from(other_one_table)
    raise "one_table_templates not empty." unless one_table_templates.blank?
    OneTable.transaction do
      other_one_table.one_table_templates.map { |ott|
        # 1. copy template itself.
        new_ott = self.one_table_templates.create ott.attributes
        # 2. copy headers
        ott.one_table_template_one_table_headers.each do |ottoth|
          new_ottoth = OneTableTemplateOneTableHeader.new ottoth.attributes
          new_ottoth.one_table_header_id =
              self.one_table_header_map[ottoth.one_table_header.sysname].id
          new_ott.one_table_template_one_table_headers << new_ottoth
        end
      }
    end
  end

  private
  def execute_import_by_filename(filename, options)
    ignore_primary_keys = false
    if self.row_size == 0
      ignore_primary_keys = true
    end
    self.namemap = options[:namemap]
    oths = one_table_headers_with_namemap
    ref2oth = oths.refmap(&:refname)
    l2o_map = oths.refmap(&:label)
    lbl2oth = oths.refmap(&:label)
    begin
      update_status 'importing'
      if filename.is_a? OneTable # copy mode.
        hdrs = filename.header_labels
        srs = filename.rows
      else
        srs = Shoji.rows filename
        hdrs = srs.shift
      end
      if options[:honor_saved_values]
        srs = srs.map { |sr| blank_to_nil(sr) }
      end

      puts "oths:#{oths.inspect}"
      puts "hdrs:#{hdrs.inspect}"
      if oths.size > hdrs.size
        match_count = 0
        hdrs.each do |hdr|
          hdr = hdr.to_s.split(/:/)[0]
          next if hdr.blank?
          unless ref2oth[hdr].blank? && lbl2oth[hdr].blank?
            match_count += 1
          end
        end
        if match_count < 2
          puts "Assume first row as data."
          sz_hdrs = hdrs.size
          srs.unshift hdrs
          hdrs = oths[0..sz_hdrs-1].map { |oth| oth.refname || oth.label }
          puts "hdrs:#{hdrs.inspect}"
          puts "srs:#{srs.inspect}"
        end
      end
      OneTable.transaction do
        hs_with_attrs = hdrs.map do |it|
          it ||= ''
          ary = it.split(/:/)
          h = ref2oth[ary[0]]
          ary[0] = h.label if h
          ary
        end
        hs_labels = hs_with_attrs.map { |it| it[0] }
        self.append_headers hs_with_attrs
        self.rows_with_headers srs, hs_labels,
                               ignore_primary_keys: ignore_primary_keys
      end
      # execute_fill_virtual_field
    rescue => e
      save_exception e
      raise e
    ensure
      reset_status
    end
  end

  def execute_deletion_by_filename(filename, options)
    raise unless options[:do_delete]
    self.namemap = options[:namemap]
    oths = one_table_headers_with_namemap
    ref2oth = oths.refmap(&:refname)
    begin
      update_status 'deleting'
      srs = Shoji.rows filename
      hdrs = srs.shift
      raise unless headers.match_primary_keys?(hdrs)
      OneTable.transaction do
        hs_with_attrs = hdrs.map do |it|
          it ||= ''
          ary = it.split(/:/)
          h = ref2oth[ary[0]]
          ary[0] = h.label if h
          ary
        end
        hs_labels = hs_with_attrs.map { |it| it[0] }
        target_row_ids = []
        srs.each do |sr|
          h = headers.hash_row(sr, hs_labels)
          target_row_ids += find(h, with_id: true).map { |r| r[:id] }
        end
        destroy_rows(target_row_ids)
      end
      execute_fill_virtual_field
    rescue => e
      save_exception e
      raise e
    ensure
      reset_status
    end
  end

  def blank_to_nil(array)
    array.map { |it| it.blank? ? nil : it }
  end
end
