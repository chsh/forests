class LoggedWordSearchActivitiesController < ApplicationController
  # GET /logged_word_search_activities
  # GET /logged_word_search_activities.xml
  def index
    @logged_word_search_activities = LoggedWordSearchActivity.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @logged_word_search_activities }
    end
  end

  # GET /logged_word_search_activities/1
  # GET /logged_word_search_activities/1.xml
  def show
    @logged_word_search_activity = LoggedWordSearchActivity.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @logged_word_search_activity }
    end
  end

  # GET /logged_word_search_activities/new
  # GET /logged_word_search_activities/new.xml
  def new
    @logged_word_search_activity = LoggedWordSearchActivity.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @logged_word_search_activity }
    end
  end

  # GET /logged_word_search_activities/1/edit
  def edit
    @logged_word_search_activity = LoggedWordSearchActivity.find(params[:id])
  end

  # POST /logged_word_search_activities
  # POST /logged_word_search_activities.xml
  def create
    @logged_word_search_activity = LoggedWordSearchActivity.new(params[:logged_word_search_activity])

    respond_to do |format|
      if @logged_word_search_activity.save
        format.html { redirect_to(@logged_word_search_activity, :notice => 'Logged word search activity was successfully created.') }
        format.xml  { render :xml => @logged_word_search_activity, :status => :created, :location => @logged_word_search_activity }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @logged_word_search_activity.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /logged_word_search_activities/1
  # PUT /logged_word_search_activities/1.xml
  def update
    @logged_word_search_activity = LoggedWordSearchActivity.find(params[:id])

    respond_to do |format|
      if @logged_word_search_activity.update_attributes(params[:logged_word_search_activity])
        format.html { redirect_to(@logged_word_search_activity, :notice => 'Logged word search activity was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @logged_word_search_activity.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /logged_word_search_activities/1
  # DELETE /logged_word_search_activities/1.xml
  def destroy
    @logged_word_search_activity = LoggedWordSearchActivity.find(params[:id])
    @logged_word_search_activity.destroy

    respond_to do |format|
      format.html { redirect_to(logged_word_search_activities_url) }
      format.xml  { head :ok }
    end
  end
end
