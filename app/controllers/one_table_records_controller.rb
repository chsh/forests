class OneTableRecordsController < PersonalController
  before_filter :one_table_record

  # GET /one_table_records
  # GET /one_table_records.xml
  def index
    authorize! :view, OneTable
    per_page = 1
    @page = (params[:page] || 0).to_i
    @rows = @one_table.rows limit: per_page, with_id: true, offset: @page * per_page
    logger.debug "rows.size: #{@rows.size}"
    @pos_start = @page * per_page + 1
    @pos_end = (@one_table.row_size - (@page * per_page + per_page) ) > 0 ? @page * per_page + per_page : @one_table.row_size
    top_record = @rows.first
    @row = @one_table.record(top_record[:id]) if top_record.present?
  end

  # GET /one_table_records/1
  # GET /one_table_records/1.xml
  def show
    authorize! :view, OneTable
    if can? :edit, OneTable
      render 'edit'
    end
  end

  # GET /one_table_records/new
  # GET /one_table_records/new.xml
  def new
    authorize! :remove, OneTable
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @row }
    end
  end

  # GET /one_table_records/1/edit
  def edit
  end

  # POST /one_table_records
  # POST /one_table_records.xml
  def create
    respond_to do |format|
      otr = regulate_record(params[:one_table_record])
      otr = @one_table.file_filter otr
      if @row.update_attributes otr
        current_user.activities.create target: @one_table,
                                       action: 'record_created'
        flash[:notice] = "OneTableRecord was successfully created."
        format.html { redirect_to(@one_table) }
        format.xml  { render :xml => @row, :status => :created, :location => @row }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @row.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /one_table_records/1
  # PUT /one_table_records/1.xml
  def update
    respond_to do |format|
      otr = regulate_record(params[:one_table_record])
      otr = @one_table.file_filter otr
      if @row.update_attributes(otr)
        current_user.activities.create target: @one_table,
                                       action: 'record_updated'
        flash[:notice] = 'OneTableRecord was successfully updated.'
        format.html { redirect_to([@one_table, @row]) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @row.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /one_table_records/1
  # DELETE /one_table_records/1.xml
  def destroy
    @row.destroy
    current_user.activities.create target: @one_table,
                                   action: 'record_deleted'
    respond_to do |format|
      format.html { redirect_to(one_table_one_table_records_path(@one_table)) }
      format.xml  { head :ok }
    end
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
          target_user.permissions.assign params[:user_permission] => @row, one_table_id: @one_table.id
          flash[:notice] = "User:#{params[:user_login]} was assigned to #{@row.id.to_s}"
          redirect_to one_table_one_table_record_path(@one_table, @row)
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
      target_user.permissions.unassign any: @row, one_table_id: @one_table.id
      flash[:notice] = "User:#{params[:user_login]} was unassigned from row: #{@row.id}"
    else
      flash[:notice] = "User:#{params[:user_login]} not found."
    end
    redirect_to one_table_one_table_record_path(@one_table, @row)
  end

  private
  def one_table_record
    @one_table = OneTable.find(params[:one_table_id])
    @row = @one_table.record(params[:id]) if params[:id].present?
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

end
