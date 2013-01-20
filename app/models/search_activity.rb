class SearchActivity < ActiveRecord::Base
  belongs_to :site
  has_many :logged_word_search_activities
  has_many :logged_words, through: :logged_word_search_activities

  validates :words, presence: true

  attr_accessor :words

  before_create do
    self[:stamped_at] = Time.now
  end
  after_create do
    log_words(words)
  end

  private
  def log_words(words)
    words.each do |word|
      logged_word_search_activities.create_link(site, word, stamped_at)
    end
  end
end
