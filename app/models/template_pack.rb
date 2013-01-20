class TemplatePack
  def self.clonable_sites(refresh = false)
    @@selection_list = nil if refresh
    @@selection_list ||= build_clonable_sites
  end
  private
  def self.build_clonable_sites
    Site.clonables.sort { |a, b|
      a.name <=> b.name
    }
  end
end
