class OneTableHeadersController < PersonalController
  # Add header management permission to removable user.
  before_filter :authorize_removable, except: %w(index show edit update)
  before_filter :authorize_editable, only: %w(edit update)
  before_filter :authorize_viewable, only: %w(index show)
  before_filter :one_table_record

  # GET /editors
  # GET /editors.xml
  def index
    @one_table_headers = @one_table.one_table_headers

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @one_table_headers }
    end
  end

  # GET /editors/new
  # GET /editors/new.xml
  def new
    @one_table_header = @one_table.one_table_headers.build
    @one_table_header.kind = OneTableHeader::KIND_TEXT

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @one_table_header }
    end
  end

  def show
  end

  # GET /editors/1/edit
  def edit
  end

  # POST /editors
  # POST /editors.xml
  def create
    @one_table_header = @one_table.send(:headers).build params[:one_table_header]

    respond_to do |format|
      if @one_table_header.save
        flash[:notice] = "OneTableHeader was successfully created."
        format.html { redirect_to one_table_one_table_headers_path(@one_table) }
        format.xml  { render :xml => @one_table_header, :status => :created, :location => @row }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @one_table_header.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /editors/1
  # PUT /editors/1.xml
  def update
    respond_to do |format|
      if @one_table_header.update_attributes(params[:one_table_header])
        flash[:notice] = 'OneTableHeader was successfully updated.'
        format.html { redirect_to one_table_one_table_headers_path(@one_table) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @one_table_header.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /editors/1
  # DELETE /editors/1.xml
  def destroy
    @one_table_header.destroy

    respond_to do |format|
      format.html { redirect_to one_table_one_table_headers_path(@one_table) }
      format.xml  { head :ok }
    end
  end

  private
  def one_table_record
    @one_table = OneTable.find(params[:one_table_id])
    @one_table_header = @one_table.one_table_headers.find(params[:id]) unless params[:id].blank?
  end
  def regulate_record(otr)
    h = {}
    otr.each do |k, v|
      case v
      when Array
        h[k] = remove_blank_values_from_array(v)
      else
        h[k] = v
      end
    end
    h
  end
  def remove_blank_values_from_array(array)
    r = []
    array.each do |it|
      r << it unless it.blank?
    end
    r
  end

  def authorize_removable
    authorize! :remove, OneTable
  end
  def authorize_editable
    authorize! :edit, OneTable
  end
  def authorize_viewable
    authorize! :view, OneTable
  end
end
