class FavUsersController < PersonalController

  def index
    @fav_users = current_user.fav_users
  end

  def show
    @one_table = current_user.one_tables.find params[:id]
  end

  def new
    @owner_user = current_user.owner_users.build
  end

  def create
    @owner_user = current_user.owner_users.build params[:owner_user]

    respond_to do |format|
      if @owner_user.save
        flash[:notice] = 'OwnerUser was successfully created.'
        format.html { redirect_to fav_users_path }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # DELETE /one_tables/1
  # DELETE /one_tables/1.xml
  def destroy
    @one_table = current_user.one_tables.find params[:id]
    @one_table.destroy

    respond_to do |format|
      format.html { redirect_to(one_tables_url) }
      format.xml  { head :ok }
    end
  end
end
