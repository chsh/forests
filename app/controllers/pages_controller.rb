class PagesController < PersonalController
  before_filter :find_site

  def regenerate
    if @site.regenerate_pages
      flash[:notice] = 'Pages were successfully created.'
    else
      flash[:notice] = "Pages' creation was failed."
    end
    redirect_to [@site, :pages]
  end

  # GET /pages
  # GET /pages.xml
  def index
    @pages = @site.pages

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @pages }
    end
  end

  # GET /pages/1
  # GET /pages/1.xml
  def show
    @page = @site.pages.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @page }
    end
  end

  # GET /pages/new
  # GET /pages/new.xml
  def new
    @page = @site.pages.build

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @page }
    end
  end

  # GET /pages/1/edit
  def edit
    @page = @site.pages.find(params[:id])
  end

  # POST /pages
  # POST /pages.xml
  def create
    @page = @site.pages.build(params[:page])

    respond_to do |format|
      if @page.save
        flash[:notice] = 'Page was successfully created.'
        format.html { redirect_to([@site, @page]) }
        format.xml  { render :xml => @page, :status => :created, :location => @page }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @page.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /pages/1
  # PUT /pages/1.xml
  def update
    @page = @site.pages.find(params[:id])

    respond_to do |format|
      if @page.update_attributes(params[:page])
        flash[:notice] = 'Page was successfully updated.'
        format.html { redirect_to([@site, @page]) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @page.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /pages/1
  # DELETE /pages/1.xml
  def destroy
    @page = @site.pages.find(params[:id])
    @page.destroy

    respond_to do |format|
      format.html { redirect_to(site_pages_url(@site)) }
      format.xml  { head :ok }
    end
  end
end
