class Service
  def self.title
    @@title ||= ccv('title') || 'incuBox'
  end
  def self.provider
    @@provider ||= ccv('provider') || 'ThinQ Corporation'
  end
  def self.developer
    @@developer ||= ccv('developer') || 'ThinQ Corporation'
  end
  def self.provider_url
    @@provider_url ||= ccv('provider_url') || 'http://thinq.jp/'
  end
  def self.developer_url
    @@developer_url ||= ccv('developer_url') || 'http://thinq.jp/'
  end
  private
  def self.ccv(cc_key)
    class_config && class_config[cc_key]
  end
end
