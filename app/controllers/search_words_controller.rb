class SearchWordsController < PersonalController
  before_filter :find_search_word_list
  # GET /search_words
  # GET /search_words.xml
  def index
    @search_words = @search_word_list.search_words

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @search_words }
    end
  end

  # GET /search_words/1
  # GET /search_words/1.xml
  def show
    @search_word = @search_word_list.search_words.find params[:id]

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @search_word }
    end
  end

  # GET /search_words/new
  # GET /search_words/new.xml
  def new
    @search_word = @search_word_list.search_words.build

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @search_word }
    end
  end

  # GET /search_words/1/edit
  def edit
    @search_word = @search_word_list.search_words.find params[:id]
  end

  # POST /search_words
  # POST /search_words.xml
  def create
    @search_word = @search_word_list.search_words.build params[:search_word]

    respond_to do |format|
      if @search_word.save
        format.html { redirect_to([@search_word_list, @search_word], :notice => 'SearchWord was successfully created.') }
        format.xml  { render :xml => @search_word, :status => :created, :location => @search_word }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @search_word.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /search_words/1
  # PUT /search_words/1.xml
  def update
    @search_word = @search_word_list.search_words.find params[:id]

    respond_to do |format|
      if @search_word.update_attributes(params[:search_word])
        format.html { redirect_to([@search_word_list, @search_word], :notice => 'SearchWord was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @search_word.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /search_words/1
  # DELETE /search_words/1.xml
  def destroy
    @search_word = @search_word_list.search_words.find params[:id]
    @search_word.destroy

    respond_to do |format|
      format.html { redirect_to(search_word_list_search_words_url(@search_word_list)) }
      format.xml  { head :ok }
    end
  end

  private
  def find_search_word_list
    @search_word_list = current_user.search_word_lists.find params[:search_word_list_id]
  end
end
