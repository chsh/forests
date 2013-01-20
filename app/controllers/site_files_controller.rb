class SiteFilesController < PersonalController
  before_filter :find_site

  def index
    @site_files = @site.site_files
  end

  def new
    @site_file = @site.site_files.build
  end

  def show
    @files = @site.files
  end

  def edit
    @site_file = @site.site_files.find params[:id]

  end

  def update
    @site_file = @site.site_files.find params[:id]
    respond_to do |format|
      if @site_file.update_attributes(params[:site_file])
        flash[:notice] = 'SiteFile was successfully updated.'
        format.html { redirect_to site_site_files_path(@site) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @site_file.errors, :status => :unprocessable_entity }
      end
    end
  end

  # POST /blocks
  # POST /blocks.xml
  def create
    sf = params[:site_file]
    if sf[:path].blank? && (sf[:file].original_filename =~ /\.zip$/i)
      @site.import_files sf[:file], :generate_pages => false
    else
      @site.site_files.create params[:site_file]
    end

    flash[:notice] = 'File was successfully created.'
    redirect_to site_site_files_path(@site)
  end

  # DELETE /blocks/1
  # DELETE /blocks/1.xml
  def destroy
    sf = @site.site_files.find params[:id]
    sf.destroy

    flash[:notice] = "#{sf.path} has been deleted."
    respond_to do |format|
      format.html { redirect_to(site_site_files_path(@site)) }
      format.xml  { head :ok }
    end
  end
  private
  def find_site
    @site = current_user.sites.find params[:site_id]
  end
end
