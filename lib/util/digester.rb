
require 'digest/sha1'
require 'digest/md5'

class Digester
  TYPEMAP = {
          :sha1 => Digest::SHA1,
          :md5 => Digest::MD5
  }
  def initialize(*strings)
    opts = strings.extract_options!
    opts.reverse_merge! :digester => :sha1
    type = TYPEMAP[opts[:digester]]
    raise "Type:#{opts[:digester]} not defined." unless type
    @digester = type.new
    strings.flatten!
    strings.each do |string|
      @digester.update string
    end
  end

  def dig
    @digester
  end

  def hexdigest
    dig.hexdigest
  end
end
