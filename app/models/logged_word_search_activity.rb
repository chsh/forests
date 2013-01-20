class LoggedWordSearchActivity < ActiveRecord::Base
  belongs_to :logged_word, counter_cache: true
  belongs_to :search_activity

  def self.create_link(site, word, stamped_at)
    lw = site.logged_words.by_word(word)
    create(logged_word_id: lw.id, stamped_at: stamped_at)
  end
end
