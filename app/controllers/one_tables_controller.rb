class OneTablesController < PersonalController

  before_filter :find_one_table, :only => [:search, :edit, :update, :show, :import, :destroy, :template, :clear_all_records, :duplicate]

  PAGING_SIZE = 1

  def search
    @query_form = QueryForm.new params[:query_form]
    @page = (params[:page] || 0).to_i
    @rows = @one_table.find @query_form.q, {with_id: true, solr: {rows: PAGING_SIZE, start: @page * PAGING_SIZE}}
    logger.debug("search:@rows.size:#{@rows.size}")
    @pos_start = @page * PAGING_SIZE + 1
    @pos_end = (@rows.metadata[:total_hits] - (@page * PAGING_SIZE + PAGING_SIZE) ) > 0 ? @page * PAGING_SIZE + PAGING_SIZE : @rows.metadata[:total_hits]
    @row = @one_table.record(@rows.first[:id])
  end
  def index
#    @one_tables = (current_user.one_tables + OneTable.is_public.all).uniq
    authorize! :view, OneTable
    @one_tables = OneTable.all
  end

  def duplicate
    authorize! :copy, OneTable
    ot = @one_table.copy_instance name: params[:one_table]['name']
    redirect_to ot, notice: t(:table_copied_starting_import)
  end

  def show
    authorize! :view, OneTable
#    render action: 'show2', layout: 'personal'
  end

  def edit
    authorize! :edit, OneTable
  end

  def new
    authorize! :manage, OneTable
    @one_table = current_user.one_tables.build
  end

  def create
    authorize! :manage, OneTable
    file = params[:one_table][:file]
    of = params[:one_table][:sysname]
    of = file.original_filename if of.blank? && !file.blank?
    @one_table = current_user.one_tables.build params[:one_table]
    OneTable.transaction do
      @one_table.save!
      flash[:notice] = "Starting to import #{of}"
    end
    redirect_to one_tables_path
  end

  def update
    authorize! :edit, OneTable
    if @one_table.update_attributes(params[:one_table])
      flash[:notice] = 'OneTable was successfully updated.'
      redirect_to one_tables_path
    else
      render action: 'edit'
    end
  end

  def import
    authorize! :edit, OneTable
    if request.put? || request.post?
      @one_table.import_uploaded params[:one_table][:file],
                       do_delete: booleanize(params[:do_delete]),
                       honor_saved_values: booleanize(params[:honor_saved_values])
      flash[:notice] = 'Starting to import data file.'
      redirect_to one_table_path(@one_table)
    end
  end

  # DELETE /one_tables/1
  # DELETE /one_tables/1.xml
  def destroy
    authorize! :remove, OneTable
    @one_table.destroy

    respond_to do |format|
      format.html { redirect_to(one_tables_url) }
      format.xml  { head :ok }
    end
  end

  def clear_all_records
    authorize! :remove, OneTable
    @one_table.clear_mongo_and_solr_documents
    flash[:notice] = "All records have been deleted."
    redirect_to one_table_path(@one_table)
  end

  def template
    authorize! :view, OneTable
    if request.get?
      send_data @one_table.template_file.content,
                :filename => @one_table.template_file.filename,
                :disposition => 'attachment'
    else
      @one_table.update_attributes params[:one_table]
      flash[:notice] = "Template updated."
      redirect_to one_table_path(@one_table)
    end
  end

  def clear_last_error
    authorize! :remove, OneTable
    @one_table = current_user.one_tables.find params[:id]
    @one_table.clear_last_error
    flash[:notice] = 'Last error cleared.'
    redirect_to one_table_path(@one_table)
  end

  def permissions
    @one_table = current_user.one_tables.find params[:id]
  end

  def assign
    @one_table = current_user.one_tables.find params[:id]
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
          target_user.permissions.assign editable: @one_table
          flash[:notice] = "User:#{params[:user_login]} was assigned to #{@one_table.name}"
          redirect_to permissions_one_table_path(@one_table)
        end
      else
        flash[:notice] = "User:#{params[:user_login]} not found."
      end
    end
  end

  def unassign
    @one_table = current_user.one_tables.find params[:id]
    raise "request verb must be delete." unless request.delete?
    target_user = User.find_by_login(params[:user_login])
    if target_user
      target_user.permissions.unassign editable: @one_table
      flash[:notice] = "User:#{params[:user_login]} was unassigned from #{@one_table.name}"
    else
      flash[:notice] = "User:#{params[:user_login]} not found."
    end
    redirect_to permissions_one_table_path(@one_table)
  end

  def download
    authorize! :view, OneTable
    @one_table = current_user.one_tables.find params[:id]
    if request.get?
      render action: 'download'
      # show download form
    else
      f = params[:download_format]
      send_data(@one_table.content_for(f, {target: params[:target]}),
                :type => 'text/csv',
                :filename => "data.#{f}")
    end
  end

  def download_csv(one_table)
    send_data(one_table.content_for_csv,
              :type => 'text/csv',
              :filename => "data.csv")
  end
  private
  def find_one_table
    @one_table = OneTable.find params[:id]
  end
end
