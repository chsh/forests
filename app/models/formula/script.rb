class Formula::Script < Formula
  def eval(row)
    Kernel.eval params[:script], binding
  end
end
