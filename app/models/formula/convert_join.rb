class Formula::ConvertJoin < Formula
  def eval(row)
    vals = (params[:fields] || []).map { |f| convert row[f] }
    join(vals)
  end
  private
  def convert(value)
    @script ||= build_script
    Kernel.eval(@script, binding)
  end
  def join(values)
    if params[:join_script]
      Kernel.eval(params[:join_script], binding)
    else
      values.join(params[:delimiter])
    end
  end
  def build_script
    if params[:script]
      params[:script]
    else
      'value'
    end
  end
end
