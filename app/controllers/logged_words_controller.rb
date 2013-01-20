class LoggedWordsController < PersonalController
  before_filter :find_site
  # GET /logged_words
  # GET /logged_words.xml
  def index
    @logged_words = @site.logged_words.order_by_count.paginate(page: params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @logged_words }
    end
  end

  # GET /logged_words/1
  # GET /logged_words/1.xml
  def show
    @logged_word = @site.logged_words.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @logged_word }
    end
  end

  private
  def find_site
    @site = current_user.sites.find params[:site_id]
  end
end
