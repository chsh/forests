class ViewerController < ApplicationController
  def index
  end
  def welcome
    if current_user
      redirect_to one_tables_path
    end
  end
  private
  def params_encoding_regulator
    @@params_encoding_regulator ||= ParamsEncodingRegulator.new(:marker_key => :em)
  end
  def site_from_virtualhost
    @@vh2s ||= build_vh2s
    @@vh2s[request.host]
  end
  def build_vh2s
    sites = Site.find(:all, :conditions => 'virtualhost is not null')
    vhsites = sites.map { |site| [site.virtualhost, site] }
    Hash[*vhsites.flatten]
  end
end
