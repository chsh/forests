module BlocksHelper
  def edit_records_path(block = nil)
    if @one_table
      edit_one_table_block_path(@one_tabe, block)
    else
      edit_block_path(block)
    end
  end
end
