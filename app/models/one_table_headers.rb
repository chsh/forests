
# OneTable のヘッダ部分を処理するクラス
# OneTableHeader[] を受け取り、 Solr レコードのキーに変換などを行う。
class OneTableHeaders
  def initialize(one_table, one_table_headers)
    @one_table = one_table
  end


  def one_table_headers
    @one_table.one_table_headers
  end

  def build(params)
    name, index = calc_name_and_index
    oth = @one_table.one_table_headers.build params
    oth.sysname = name
    oth.index = index
    oth
  end
  def create(params)
    oth = build params
    oth.save
    oth
  end

  def solr_record(hash, one_table, record_index)
    hb = {}
    rebuild_sysname_to_one_table_header_map
    hash.each do |sysname, value|
      next if value.blank?
      header = sysname_to_one_table_header_map[sysname]
      hb.merge!(hash_from_pair(header.solr_key_and_value_pairs(value)))
    end
    KeyIdentifier.append_solr_keys(hb, KeyIdentifier.one_table_key_from_object(one_table), record_index)
  end
  def hash_row(values, keys = nil)
    if keys
      if keys.size != values.size
        values = resize_array(values, keys.size)
      end
      hash_row_with_key([keys, values].transpose)
    else
      hash_row_without_key(values)
    end
  end

  def primary_keys_from_hash(hash)
    kvs = primary_sysnames.map { |sysname|
      [sysname, hash[sysname]]
    }.flatten
    Hash[*kvs]
  end

  def match_primary_keys?(keys)
    primary_labels.size == keys.size && (primary_labels - keys).empty?
  end

  def hash_row_with_key(keys_and_values)
    key_oth_array = one_table_headers.map do |oth|
      if oth.refname.blank?
        [oth.label, oth]
      else
        [oth.label, oth, oth.refname, oth]
      end
    end
    key2oth = Hash[*key_oth_array.flatten]
    r = {}
    keys_and_values.each do |key, value|
      unless (key.blank? || value.nil?)
        oth = key2oth[key]
        kv = oth.key_and_value(value)
        r[kv[0]] = kv[1]
      end
    end
    r
  end
  def hash_row_without_key(values)
    hb = {}
    one_table_headers.each_with_index do |header, index|
      v = values[index]
      unless v.nil?
        kv = header.key_and_value(v)
        hb[kv[0]] = kv[1]
      end
    end
    hb
  end
  def solred_row(values, one_table, record_index)
    solr_record hash_row(values), one_table, record_index
  end

  def sysname_to_one_table_header_map(force_reload = false)
    @sysname_to_one_table_header_map = nil if force_reload
    @sysname_to_one_table_header_map ||= build_sysname_to_one_table_header_map
  end

  private
  def rebuild_sysname_to_one_table_header_map
    sysname_to_one_table_header_map(true)
  end
  def build_sysname_to_one_table_header_map
    one_table_headers.refmap(&:sysname)
  end
  def calc_name_and_index
    if last_header = one_table_headers.last
      last_name = last_header.sysname
      last_index = last_header.index
      [next_index_name(last_name), last_index + 1]
    else
      ['h0', 0]
    end
  end
  def next_index_name(last_name)
    index = KeyIdentifier.header_index(last_name) + 1
    KeyIdentifier.header_key index
  end

  def resize_array(values, size)
    return values if values.size == size
    if values.size > size
      values[0, size]
    else # values.size < size
      values + [nil] * (size - values.size)
    end
  end

  def hash_from_pair(values)
    raise "values.size must be even." unless (values.size % 2) == 0
    h = {}
    (values.size / 2).times do |i|
      h[values[i*2]] = values[i*2+1]
    end
    h
  end
  def primary_sysnames
    @primary_sysnames ||= build_primary_sysnames
  end
  def primary_labels
    @primary_labels ||= build_primary_labels
  end
  def build_primary_sysnames
    one_table_headers.map { |oth|
      oth.sysname if oth.primary_key?
    }.compact
  end
  def build_primary_labels
    one_table_headers.map { |oth|
      oth.label if oth.primary_key?
    }.compact
  end
end
