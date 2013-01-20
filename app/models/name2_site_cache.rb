
class Name2SiteCache
  def initialize
    @n2s = nil
  end

  def [](name)
    @n2s ||= build_n2s
    @n2s[name] || update_n2s(name)
  end

  private
  def build_n2s
    sites = Site.all
    vhsites = sites.map { |site| [site.name, site] }
    Hash[*vhsites.flatten]
  end
  def update_n2s(name)
    site = Site.find_by_name name
    return nil unless site
    @n2s[name] = site
  end
end
