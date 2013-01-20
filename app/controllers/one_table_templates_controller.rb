class OneTableTemplatesController < PersonalController
  before_filter :find_one_table
  before_filter :verify_one_table_template_creatable
  # GET /one_table_templates
  # GET /one_table_templates.json
  def index
    @one_table_templates =
        @one_table.
            one_table_templates.
            by_user(current_user)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @one_table_templates }
    end
  end

  # GET /one_table_templates/1
  # GET /one_table_templates/1.json
  def show
    @one_table_template =
        @one_table.
            one_table_templates.
            by_user(current_user).
            find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @one_table_template }
    end
  end

  # GET /one_table_templates/new
  # GET /one_table_templates/new.json
  def new
    @one_table_template = @one_table.one_table_templates.build
    if params[:q]
      @one_table_template.query = params[:q]
      @one_table_template.name = "Search #{params[:q]}"
    end
    @one_table.one_table_headers.each_with_index do |oth, index|
      @one_table_template.
          one_table_template_one_table_headers <<
          OneTableTemplateOneTableHeader.new(
              one_table_header: oth,
              display_index: index
          )
    end

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @one_table_template }
    end
  end

  # GET /one_table_templates/1/edit
  def edit
    @one_table_template =
        @one_table.
            one_table_templates.
            by_user(current_user).
            find(params[:id])
  end

  # POST /one_table_templates
  # POST /one_table_templates.json
  def create
    @one_table_template =
        @one_table.
            one_table_templates.
            by_user(current_user).
            build(params[:one_table_template])

(params[:one_table_template])
    @one_table_template.user_id = current_user.id

    respond_to do |format|
      if @one_table_template.save
        format.html { redirect_to [@one_table, @one_table_template], notice: t(:one_table_template_created) }
        format.json { render json: @one_table_template, status: :created, location: @one_table_template }
      else
        format.html { render action: "new" }
        format.json { render json: @one_table_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /one_table_templates/1
  # PUT /one_table_templates/1.json
  def update
    @one_table_template =
        @one_table.
            one_table_templates.
            by_user(current_user).
            find(params[:id])

    respond_to do |format|
      if @one_table_template.update_attributes(params[:one_table_template])
        format.html { redirect_to [@one_table, @one_table_template], notice: t(:one_table_template_updated) }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @one_table_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /one_table_templates/1
  # DELETE /one_table_templates/1.json
  def destroy
    @one_table_template =
        @one_table.
            one_table_templates.
            by_user(current_user).
            find(params[:id])
    @one_table_template.destroy

    respond_to do |format|
      format.html { redirect_to one_table_one_table_templates_url(@one_table) }
      format.json { head :no_content }
    end
  end

  def download
    @one_table_template =
        @one_table.
            one_table_templates.
            by_user(current_user).
            find(params[:id])
    current_user.activities.create target: @one_table_template,
                                   action: 'download'
    current_time = Time.now.strftime '%Y%m%d-%H%M'
    send_data(@one_table_template.content_for,
              type: "text/#{@one_table_template.output_format_as_string}",
              filename: "data-#{current_time}.#{@one_table_template.output_format_as_string}")
  end

  def import
    if request.put? || request.post?
      @one_table_template =
          @one_table.
              one_table_templates.
              by_user(current_user).
              find(params[:id])
      @one_table_template.import_uploaded params[:one_table_template][:file]
      flash[:notice] = 'Starting to import data file.'
      redirect_to one_table_path(@one_table)
    end
  end

  private
  def verify_one_table_template_creatable
    @one_table.one_table_template_creatable?
  end

end
