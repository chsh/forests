

Site.all.each do |site|
  p2sf = site.site_files.refmap(&:path)
  site.files.list_names.each do |path|
    unless p2sf[path]
      site.site_files.create :path => path
      puts "site:#{site.name}, path:#{path} created."
    end
  end
end
