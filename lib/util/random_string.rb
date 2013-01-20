class RandomString
  ASCII_SMALL = ('a'..'z').to_a - ['o', 'l']
  ASCII_LARGE = ('A'..'Z').to_a - ['O', 'I']
  NUMBER = ('1'..'9').to_a
  ASCII = ASCII_SMALL + ASCII_LARGE
  SYMBOLS = '!#$%*+-./<=>@^_'.split(//)
  TYPEMAP = {
          :ascii_small => ASCII_SMALL,
          :ascii_large => ASCII_LARGE,
          :ascii => ASCII,
          :number => NUMBER,
          :numbers => NUMBER,
          :symbol => SYMBOLS,
          :symbols => SYMBOLS,
          :url_safe => ASCII + NUMBER,
  }
  def self.generate(*types)
    opts = types.extract_options!
    opts.reverse_merge! :length => 40
    chars = character_set(*types)
    (1 .. opts[:length].to_i).map { |i| chars[rand(chars.size)] }.join('')
  end

  def self.character_set(*types)
    types.flatten!
    chars = types.map do |type|
      case type
      when Symbol then (TYPEMAP[type] || [])
      when String then type.split(//)
      else raise "Unexpected type type:#{type.class}"
      end
    end
    chars.flatten.sort.uniq
  end
end
