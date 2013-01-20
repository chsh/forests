
class OneTableRecord
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  def persisted?; id ? true : false; end

  attr_accessor :id, :one_table, :permission

  def to_param
    self.id.to_s
  end

  def new_record?; self.id.nil?; end

  def owner?(current_user)
    one_table.user_id == current_user.id
  end

  def self.find(id, options = {})
    ot = OneTable.find(options[:one_table_id])
    ot.record id
  end
  def id
   case @id
   when BSON::ObjectId then @id.to_s
   when nil then nil
   when String then @id
   else @id.to_s
   end
  end

  def [](key)
    refer key
  end
  def destroy
    one_table.destroy_row self.id
  end
  def self.from(mongo_record, one_table)
    if mongo_record
      from_mongo_record(mongo_record, one_table)
    else
      build_new_record(one_table)
    end
  end
  # attrs = {'h0' => value0, 'h1' => value1 ...}
  def update_attributes(attrs, mongo_and_solr_opts = {}, save_opts = {})
    save_opts.reverse_merge! run_aftersave_hooks: true
    new_attrs = merge_to_intributes attrs
    new_intributes = update_virtual_attributes new_attrs
    result = one_table.send :save_mongo_and_solr_by_hash, new_intributes, self.id, mongo_and_solr_opts
    self.id = result unless self.id
    if save_opts[:run_aftersave_hooks]
      one_table.send(:run_hooks, 'after:save', last_modified: Time.now )
    end
    true
  end
  def each(&block)
    raise "Block must be given." unless block_given?
    sorted_intributes_keys.each_with_index do |k, i|
      block.call k, one_table.header_labels[i]
    end
  end

  def virtual_field?(label)
    self.one_table.send(:label_to_header)[label].formula ? true : false
  end

  def file_field?(label)
    self.one_table.send(:label_to_header)[label].file_field?
  end

  def multiple_field?(label)
    self.one_table.send(:label_to_header)[label].multiple?
  end

  def sorted_intributes_keys
    intributes.keys.sort do |a, b|
      KeyIdentifier.compare(a, b)
    end
  end

  def intributes
    @intributes ||= BSON::OrderedHash.new
  end

  def method_missing(method, *args)
    sm = method.to_s.gsub(/_before_type_cast$/, '')
    if sm.last == '='
      raise "arg must have only one parameter." unless args.size == 1
      alter sm.chop, args[0]
    else
      refer sm
    end
  end
  private
  def self.from_mongo_record(mongo_record, one_table)
    instance = new
    instance.id = mongo_record.delete '_id'
    instance.one_table = one_table
    mongo_record.each do |key, value|
      instance.send :alter, key, value
    end
    instance
  end
  def self.build_new_record(one_table)
    instance = new
    instance.one_table = one_table
    one_table.one_table_headers.each do |header|
      instance.send :alter, header.sysname, nil
    end
    instance
  end
  def alter(key, value)
    intributes[key] = value
  end
  def refer(key)
    intributes[key]
  end
  def fix_attrs_keys(attrs, one_table)
    h = {}
    attrs.each do |key, value|
      h[KeyIdentifier.combine_ids(one_table, key)] = value
    end
    h
  end

  def update_virtual_attributes(new_intributes)
    oths_w_formulas = self.one_table.one_table_headers.find_virtual_headers
    name_values = oths_w_formulas.map do |oth|
      [oth.sysname, oth.formula.eval(new_intributes)]
    end
    new_intributes.merge Hash[*name_values.flatten]
  end
  def merge_to_intributes(attrs)
    new_attrs = intributes.clone
    attrs.each do |k, v|
      oth = self.one_table.send(:label_to_header)[k]
      if oth.file_field?
        if v.is_a? MetaString
          v.metadata[:removed_path] = intributes[k]
          new_attrs[k] = v
        end
      else
        new_attrs[k] = v
      end
    end
    new_attrs
  end
end
