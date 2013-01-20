class ClassCache

  def self.for(klass)
    redis = class_config.redis
    Redis::Namespace.new("#{redis.namespace}:#{klass.name.underscore}", :redis => Redis.new(:host => redis.host, :port => redis.port))
  end
end
