
# generic key value store holder.

class KVStore

  def initialize(context = 'default', opts = {}, &block)
    @source = self.class.source.new(context, opts, &block)
  end
  def self.open(context = 'default', opts = {}, &block)
    source.new(context, opts, &block)
  end
  def [](key)
    @source[key]
  end
  def []=(key, value)
    @source[key] = value
  end
  def delete(key)
    @source.delete(key)
  end

  private
  def self.source(force_reload = false)
    @@source_class = nil if force_reload
    @@source_class ||= eval class_config.source.to_s.camelcase
  end
end

class KVStore::Base
  attr_reader :opts
  def initialize(context = 'default', opts = {}, &block)
    @opts = opts
    @context = context
    if block_given?
      open
      block.call(self)
      close
    end
  end
  def self.open(opts = {}, &block)
    new(opts, &block)
  end
  def open
    @con = connection_with_context @context
  end
  def close
  end
  def run_block(&block)
    if @con
      block.call(self)
    else
      r = nil
      open
      r = block.call(self)
      close
      r
    end
  end
  def [](key)
    run_block do |me|
      me.send :get, key
    end
  end
  def []=(key, value)
    run_block do |me|
      me.send :put, key, value
    end
  end
  def delete(key)
    run_block do |me|
      me.send :delete_within_block, key
    end
  end
  protected
  def get(key)
    raise NotImplementedError.new
  end
  def put(key, value)
    raise NotImplementedError.new
  end
  protected
  def connection_with_context(context)
    raise NotImplementedError.new
  end
end
