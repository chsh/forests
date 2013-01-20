class KeyIdentifier
  def self.header_key(index)
    "h#{index}"
  end
  def self.header_index(key)
    if key =~ /^h(\d+)$/
      $1.to_i
    end
  end
  def self.extract_id(key)
    if key =~ /^h(\d+)$/
      $1.to_i
    end
  end
  def self.compare(a, b)
    ea = extract_id(a)
    eb = extract_id(b)
    raise if ea.nil? || eb.nil?
    ea <=> eb
  end

  def self.combine_ids(one_table, header)
    ot_key = one_table_key_from_object one_table
    h_key = header_key_from_object header
    "#{ot_key}#{h_key}"
  end

  def self.append_solr_keys(h, collection_key, collection_index)
    h['dom_ks'] = collection_key
    h['dom_ki'] = collection_index
    h['id'] = "#{collection_key}_#{collection_index}"
    h
  end

  def self.one_table_key(value)
    "ot#{value}"
  end

  def self.solr_collection_query(value)
    "dom_ks:#{one_table_key(value)}"
  end

  private
  def self.one_table_key_from_object(one_table)
    if one_table.is_a?(String) && one_table =~ /^ot\d+$/
      one_table
    elsif !one_table.nil? && one_table.respond_to?(:to_param)
      "ot#{one_table.to_param}"
    else raise "Unexpected parameter."
    end
  end
  def self.header_key_from_object(header)
    if header.is_a?(String) && header =~ /^h\d+$/
      header
    elsif !header.nil? && header.respond_to?(:to_param)
      "h#{header.to_param}"
    else raise "Unexpected parameter."
    end
  end
end
