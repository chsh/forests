class SearchWordList < ActiveRecord::Base
  belongs_to :user
  has_many :search_words, :dependent => :delete_all, :order => 'index'
  def search_words_for_select_or_checkbox
    self.search_words.map { |sw| [sw.display_value, sw.search_value ]}
  end
end
