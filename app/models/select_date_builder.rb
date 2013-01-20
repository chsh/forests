# encoding: UTF-8
class SelectDateBuilder
  def initialize(default_date = nil)
    @default = default_date
    @today = Date.today
  end
  def default=(default_date)
    @default = default_date
  end
  def build(name)
    [select_year(name), select_month(name), select_day(name)].join(" ")
  end
  def select_year(name)
    values = years_after(@today.year, 2)
    tag(:select, :name => "#{name}[y]") do
      values = values.map do |year|
        if @default && @default.year == year
          "<option value=\"#{year}\" selected=\"selected\">#{year}年</option>"
        else
          "<option value=\"#{year}\">#{year}年</option>"
        end
      end
      values.unshift "<option value=''></option>"
      values
    end
  end
  def select_month(name)
    tag(:select, :name => "#{name}[m]") do
      values = (1..12).map do |month|
        if @default && @default.month == month
          "<option value=\"#{month}\" selected=\"selected\">#{month}月</option>"
        else
          "<option value=\"#{month}\">#{month}月</option>"
        end
      end
      values.unshift "<option value=''></option>"
      values
    end
  end
  def select_day(name)
    tag(:select, :name => "#{name}[d]") do
      values = (1..31).map do |day|
        if @default && @default.day == day
          "<option value=\"#{day}\" selected=\"selected\">#{day}日</option>"
        else
          "<option value=\"#{day}\">#{day}日</option>"
        end
      end
      values.unshift "<option value=''></option>"
      values
    end
  end
  private
  def years_after(year, num)
    (0 ... num).map { |offset| year + offset }
  end
  def tag(name, opts = {})
    if block_given?
      [begin_tag(name, opts),
       [yield].flatten.join,
       end_tag(name)].join("\n")
    else
      single_tag(name, opts)
    end
  end
  def begin_tag(name, opts = {})
    "<#{name}" + opt_attrs(opts) + ">"
  end
  def opt_attrs(opts)
    opts.map do |key, value|
      " #{key}=\"#{value}\""
    end.join('')
  end
  def end_tag(name)
    "</#{name}>"
  end
  def single_tag(name, opts = {})
    "<#{name}" + opt_attrs(opts) + "/>"
  end
end
