class WordLogger
  def self.log(site, params)
    words = words_from_params(params)
    site.search_activities.create words: words
  end
  private
  def self.words_from_params(params)
    words = []
    params.each do |key, value|
      if key.to_s =~ /^h(t|\d+)$/ && value.is_a?(String) && value.present?
        words << Moji.normalize_zen_han(value).downcase.split(/[\s\u3000]+/)
      end
    end
    words.flatten.uniq
  end
end
