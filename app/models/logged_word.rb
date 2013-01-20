class LoggedWord < ActiveRecord::Base
  belongs_to :site
  has_many :logged_word_search_activities
  has_many :search_activities, through: :logged_word_search_activities

  def self.by_word(word)
    find_by_value(word) || create(value: word)
  end

  def self.words
    all.map(&:value)
  end

  def count
    logged_word_search_activities_count
  end

  scope :order_by_count, order('logged_word_search_activities_count desc')
end
