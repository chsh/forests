class MemoryStore < KVStore::Base
  def get(key)
    @con[key]
  end
  def put(key, value)
    @con[key] = value
  end
  def delete_within_block(key)
    @con.delete key
  end
  def connection_with_context(context)
    @@contexts ||= {}
    @@contexts[context] ||= {}
  end
  def close
    return unless @con
    @con = nil
  end
  private
  def self.clear_contexts
    @@contexts = nil
  end
end
