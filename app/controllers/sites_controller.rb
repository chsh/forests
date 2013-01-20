class SitesController < PersonalController

  before_filter :find_site, :except => [:index, :create, :new, :new2]
  before_filter :verify_creatable, :only => [:new, :create]
  before_filter :verify_removable, :only => [:destroy]
  before_filter :verify_editable, :only => [:edit, :update]
  before_filter :verify_viewable, :only => [:show]

  # EXTENSION:FORESTS: BEGIN
  def search_export
    path = "search-export-#{Time.now.strftime('%Y%m%d-%H%M%S-')}#{rand(32)}.zip"
    @site.search_export(File.join(Rails.root, 'public', path), request.host_with_port)
    redirect_to "/#{path}"
  end
  # EXTENSION:FORESTS: END
  # GET /sites
  # GET /sites.xml
  def index
    @sites = current_user.sites

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @sites }
    end
  end

  # GET /sites/1
  # GET /sites/1.xml
  def show

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @site }
    end
  end

  # GET /sites/new
  # GET /sites/new.xml
  def new
    @my_sites = current_user.sites.clone
    @site = current_user.sites.build

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @site }
    end
  end

  def new2
    @site = current_user.sites.build
    unless params[:source_site_id] == '0'
      @site.source_from params[:source_site_id]
    end
  end

  def attributes
    unless request.get?
      @site.site_attributes = params[:hash].to_hash
      respond_to do |format|
        if @site.save
          flash[:notice] = 'Site attributes were successfully updated.'
        else
          flash[:notice] = 'Fail to update Site attributes.'
        end
        format.html { redirect_to(attributes_site_path(@site)) }
        format.xml  { render :xml => @site, :status => :created, :location => @site }
      end
    end
  end

  # GET /sites/1/edit
  def edit
  end

  # POST /sites
  # POST /sites.xml
  def create
    params[:site][:virtualhost] = nil if params[:site][:virtualhost] =~ /^\s*$/
    @site = current_user.sites.build(params[:site])

    respond_to do |format|
      if @site.save
        flash[:notice] = 'Site was successfully created.'
        format.html { redirect_to(@site) }
        format.xml  { render :xml => @site, :status => :created, :location => @site }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @site.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /sites/1
  # PUT /sites/1.xml
  def update
    params[:site][:virtualhost] = nil if params[:site][:virtualhost] =~ /^\s*$/

    respond_to do |format|
      if @site.update_attributes(params[:site])
        flash[:notice] = 'Site was successfully updated.'
        format.html { redirect_to(@site) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @site.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /sites/1
  # DELETE /sites/1.xml
  def destroy
    @site.destroy

    respond_to do |format|
      format.html { redirect_to(sites_url) }
      format.xml  { head :ok }
    end
  end

  def ref_tables
  end

  def assign
    if request.get?
      # render form
    else # post/create
      target_user = User.find_by_login(params[:user_login])
      if target_user
        if target_user.id == current_user.id
          flash[:notice] = t(:cannot_assign_myself)
        elsif target_user.admin?
          flash[:notice] = t(:admin_always_operate_everything)
        else
          target_user.permissions.assign params[:user_permission] => @site
          flash[:notice] = "User:#{params[:user_login]} was assigned to site: #{@site.name}"
          redirect_to permissions_site_path(@site)
        end
      else
        flash[:notice] = "User:#{params[:user_login]} not found."
      end
    end
  end

  def unassign
    raise "request verb must be delete." unless request.delete?
    target_user = User.find_by_login(params[:user_login])
    if target_user
      target_user.permissions.unassign any: @site
      flash[:notice] = "User:#{params[:user_login]} was unassigned from site:#{@site.name}"
    else
      flash[:notice] = "User:#{params[:user_login]} not found."
    end
    redirect_to permissions_site_path(@site)
  end

  def permissions
  end

  private
  def find_site
    @site = Site.find(params[:id])
  end
  def verify_creatable
    verify_permission(:creatable, Site)
  end
  def verify_removable
    verify_permission(:removable, @site)
  end
  def verify_editable
    verify_permission(:editable, @site)
  end
  def verify_viewable
    verify_permission(:viewable, @site)
  end
  def verify_permission(cmd, target)
    raise unless current_user.permissions.send("#{cmd}?", target)
  end
end
