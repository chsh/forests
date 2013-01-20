class SearchActivitiesController < PersonalController
  before_filter :find_site
  # GET /search_activities
  # GET /search_activities.xml
  def index
    @search_activities = @site.search_activities.order('stamped_at desc').paginate(page: params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @search_activities }
    end
  end

  # GET /search_activities/1
  # GET /search_activities/1.xml
  def show
    @search_activity = @site.search_activities.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @search_activity }
    end
  end

  private
  def find_site
    @site = current_user.sites.find params[:site_id]
  end
end
