class BlocksController < PersonalController
  before_filter :find_site
  # GET /blocks
  # GET /blocks.xml
  def index
    @blocks = @site.blocks

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @blocks }
    end
  end

  # GET /blocks/1
  # GET /blocks/1.xml
  def show
    @block = @site.blocks.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @block }
    end
  end

  # GET /blocks/new
  # GET /blocks/new.xml
  def new
    @block = @site.blocks.build

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @block }
    end
  end

  # GET /blocks/1/edit
  def edit
    @block = @site.blocks.find(params[:id])
    kind_to_action = {
            Block::KIND_SEARCH_ITEMS => 'edit_search_items',
            Block::KIND_DISPLAY_ITEMS => 'edit_display_items',
            Block::KIND_LIST_DISPLAY_ITEMS => 'edit_list_display_items'
    }.with_default('edit')
    render :action => kind_to_action[@block.kind]
  end

  # POST /blocks
  # POST /blocks.xml
  def create
    @block = @site.blocks.build(params[:block])
    @block.user_id = current_user.id

    respond_to do |format|
      if @block.save
        flash[:notice] = 'Block was successfully created.'
        format.html { redirect_to(one_table_blocks_path(@one_table)) }
        format.xml  { render :xml => @block, :status => :created, :location => @block }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @block.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /blocks/1
  # PUT /blocks/1.xml
  def update
    @block = @site.blocks.find(params[:id])

    respond_to do |format|
      params[:block].delete :user_id
      if @block.update_attributes(params[:block])
        flash[:notice] = 'Block was successfully updated.'
        format.html { redirect_to([@site, @block]) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @block.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /blocks/1
  # DELETE /blocks/1.xml
  def destroy
    @block = @site.blocks.find(params[:id])
    @block.destroy

    respond_to do |format|
      format.html { redirect_to(blocks_url) }
      format.xml  { head :ok }
    end
  end

  private
  def find_site
    @site = current_user.sites.find params[:site_id]
  end
end
