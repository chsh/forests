# SiteAttributes depends on Site instance.
class SiteAttributes
  def initialize(site)
    @site = site
    refresh_ref_hash
  end
  def []=(key, value)
    ks = key.to_s
    SiteAttribute.transaction do
      sa = @site.site_attributes.find_by_key ks
      if sa
        sa.update_attributes :value => value
      else
        @site.site_attributes.create :key => ks, :value => value
      end
    end
    refresh_ref_hash true
    value
  end
  def [](key)
    ks = key.to_s
    @ref_hash[ks] ||= value_by_key ks
  end
  def delete(key)
    sa = @site.site_attributes.find_by_key key.to_s
    sa.destroy if sa
  end
  private
  def value_by_key(key)
    sa = @site.site_attributes.find_by_key key
    return nil unless sa
    sa.value
  end
  def refresh_ref_hash(force_reload = false)
    @ref_hash = Hash[*@site.site_attributes(force_reload).map { |sa| [sa.key, sa.value] }.flatten]
  end
  attr_reader :ref_hash
end
