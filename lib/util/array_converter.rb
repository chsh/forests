class ArrayConverter
  # convert from ['1','2','3'] to ['123', '12', '13', '23', '1', '2', '3']
  # pl[1,2,3] -> 1, pl[2,3]
  # pl[2,3] -> 2, pl[3]
  def self.partial_list(*array)
    opts = array.extract_options!
    opts.reverse_merge! :delimiter => ''
    combine_partial_list([array].flatten.map { |v| v.to_s }.sort, opts)
  end

  private
  def self.combine_partial_list(least, opts = {})
    return [] if least.size == 0
    first = least.shift
    cpl = combine_partial_list(least, opts)
    return [first] if cpl.size == 0
    [first, cpl.map { |v| [first, v].join(opts[:delimiter]) }, cpl].flatten
  end
end
