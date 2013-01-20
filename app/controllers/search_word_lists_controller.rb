class SearchWordListsController < ApplicationController
  # GET /search_word_lists
  # GET /search_word_lists.xml
  def index
    @search_word_lists = current_user.search_word_lists

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @search_word_lists }
    end
  end

  # GET /search_word_lists/1
  # GET /search_word_lists/1.xml
  def show
    @search_word_list = current_user.search_word_lists.find params[:id]

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @search_word_list }
    end
  end

  # GET /search_word_lists/new
  # GET /search_word_lists/new.xml
  def new
    @search_word_list = current_user.search_word_lists.build

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @search_word_list }
    end
  end

  # GET /search_word_lists/1/edit
  def edit
    @search_word_list = current_user.search_word_lists.find params[:id]
  end

  # POST /search_word_lists
  # POST /search_word_lists.xml
  def create
    @search_word_list = current_user.search_word_lists.build params[:search_word_list]

    respond_to do |format|
      if @search_word_list.save
        format.html { redirect_to(@search_word_list, :notice => 'SearchWordList was successfully created.') }
        format.xml  { render :xml => @search_word_list, :status => :created, :location => @search_word_list }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @search_word_list.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /search_word_lists/1
  # PUT /search_word_lists/1.xml
  def update
    @search_word_list = current_user.search_word_lists.find params[:id]

    respond_to do |format|
      if @search_word_list.update_attributes(params[:search_word_list])
        format.html { redirect_to(@search_word_list, :notice => 'SearchWordList was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @search_word_list.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /search_word_lists/1
  # DELETE /search_word_lists/1.xml
  def destroy
    @search_word_list = current_user.search_word_lists.find params[:id]
    @search_word_list.destroy

    respond_to do |format|
      format.html { redirect_to(search_word_lists_url) }
      format.xml  { head :ok }
    end
  end
end
