class TableReader
  attr_reader :headers, :rows
  def initialize(headers, rows)
    raise "Headers must have values." if headers.blank? && rows.size > 0
    headers ||= []
    @headers = headers.map { |header|
      if header.is_a?(Array)
        header[0]
      else
        header
      end
    }
    @rows = rows
  end

  def count
    @rows.size
  end

  def sort(*args)
    css = sorters_from_args args
    new_rows = delete_missing(@rows, css)
    sorted_rows = new_rows.sort do |a, b|
      compare_values(a, b, css)
    end
    TableReader.new(headers, sorted_rows)
  end

  def self.from_hash_array(array)
    rows = []
    headers = nil
    array.each do |hash|
      headers ||= hash.keys.sort
      hsz = headers.size
      ksz = hash.keys.size
      skeys = hash.keys.sort
      if hsz < ksz
        raise "large keys must include headers.: headers=#{headers.inspect}, hash.keys.sort:#{skeys.inspect}" unless (headers & skeys) == headers
        headers = skeys
      elsif hsz == ksz
        raise "keys must be equal for headers.: headers=#{headers.inspect}, hash.keys.sort:#{skeys.inspect}" unless headers == skeys
      else # hsz > ksz
        raise "headers must include small keys.: headers=#{headers.inspect}, hash.keys.sort:#{skeys.inspect}" unless (headers & skeys) == skeys
      end
    end
    array.each do |hash|
      row = []
      headers.each do |key|
        row << hash[key]
      end
      rows << row
    end
    new(headers, rows)
  end

  def squeeze(conditions)
    self.class.new @headers, @rows.map { |row|
      h = row_hash(row)
      row if match_conditions?(conditions, h)
    }.compact
  end

  def at(index)
    @rows[index]
  end
  def at_hash(index)
    row = at index
    row_hash row
  end
  def row_hash(row)
    Hash[*@headers.map_with_index { |h, i|
      [h, row[i]]
    }.flatten]
  end
  def distinct_values(key, conditions = {})
    vals = []
    @rows.each do |row|
      h = row_hash(row)
      next unless match_conditions?(conditions, h)
      val = h[key].to_s
      unless vals.include? val
        vals << MetaString.from(val, h)
      end
    end
    vals
  end
  def select_rows(conditions)
    r = []
    @rows.each do |row|
      r << row if match_conditions? conditions, row_hash(row)
    end
    r
  end
  private
  def match_conditions?(conditions, hash)
    conditions.each do |header, value|
      return false unless hash[header] == value
    end
    true
  end
  def sorters_from_args(args)
    args = args.map { |arg| arg.split(',') }.flatten
    args.map do |arg|
      a = arg.strip.split(/\s+/)
      [hi_by_value(a[0]), tf_by_value(a[1], 'asc', 'desc')]
    end
  end
  def hi_by_value(name)
    index = @headers.index name
    raise "Column name:#{name} not found" unless index
    index
  end
  def tf_by_value(src, true_value, false_value)
    return true if src == true_value
    return false if src == false_value
    raise "Unexpected src value:#{src}"
  end
  def values_by_css(row, css_indexes)
    css_indexes.map { |ci| row[ci] }
  end
  def compare_values(a, b, css)
    css.each do |index, fwd|
      dd = detect_dir(a[index], b[index], fwd)
      return dd if dd
    end
    0
  end
  def detect_dir(va, vb, fwd)
    return nil if va == vb
    if fwd
      va <=> vb
    else
      vb <=> va
    end
  end
  def delete_missing(target_rows, css)
    target_rows.map do |row|
      has_nil = false
      css.each do |index, fwd|
        if row[index].nil?
          has_nil = true
          break
        end
      end
      if has_nil
        nil
      else
        row
      end
    end.compact
  end

end
