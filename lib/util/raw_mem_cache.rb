class RawMemCache
  def self.[](key)
    raw_mem_cache[key]
  end
  def self.[]=(key, value)
    raw_mem_cache[key] = value
  end
  def self.invalidate!(key)
    raw_mem_cache.invalidate!(key)
  end
  def self.raw_mem_cache
    @@instance ||= build_raw_mem_cache
  end
  def self.mem_cache?
    raw_mem_cache.mem_cache?
  end
  private
  def self.build_raw_mem_cache
    # verify memcached existence
    return null_cache if ::MemCache.class_config == nil
    return null_cache if ::MemCache.class_config['host'] == nil
    return null_cache if server_down?
    MemCache.new
  end
  def self.null_cache
    @@null_cache ||= NullCache.new
  end
  def self.server_down?
    mc = ::MemCache.new ::MemCache.class_config['host']
    has_error = false
    begin
      mc.stats
    rescue
      has_error = true
    end
    has_error
  end
end

class RawMemCache::MemCache
  def [](key)
    raw_mem_cache.get(key, true)
  end
  def []=(key, value)
    raw_mem_cache.add(key, value, 0, true)
  end
  def invalidate!(key)
    raw_mem_cache.delete(key)
  end
  def mem_cache?; true; end
  private
  def raw_mem_cache
    @raw_mem_cache ||= ::MemCache.new MemCache.class_config['host']
  end
end

class RawMemCache::NullCache
  def [](key)
    nil
  end
  def []=(key, value)
    nil
  end
  def invalidate!(key)
    nil
  end
  def mem_cache?; false; end
end
