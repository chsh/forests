class Formula::Join < Formula
  def eval(row)
    vals = (params[:fields] || []).map { |f| row[f] }
    vals.join(params[:delimiter])
  end
end
