require 'uri'

class SiteViewController < ApplicationController
  def index
    result = analyze
    return if process_result(result)
    return if redirect_for_root
    site = site_from_virtualhost
    full_path = nil
    if site
      full_path = request_path
    else
      if request_path =~ /^\/([^\/]+)(\/.*)$/
        sitename = $1; full_path = $2
        site = site_from_name(sitename)
      end
      raise ActiveRecord::RecordNotFound.new("Site not found. virtualhost:#{request.host}, path:#{request_path}") unless site
    end
    if full_path.last == '/'
      full_path += 'index.html'
    end
    full_path = fix_ext(full_path, '.html')
    full_path = full_path[1, full_path.length-1]
    page, matches = site.matched_page full_path
    if page
      params_encoding_regulator.regulate params
      text = page.render_content(params, matches)
      ct = nil
      if params[:content_type]
        ct = params[:content_type]
      else
        ct = content_type_from_path(full_path)
      end
      response.header['Content-Type'] = ct unless ct.blank?
      render :text => text
    else
      redirect_to '/404.html'
    end
  end

  CONTENT_TYPE_MAP = {
      /\.html$/i => 'text/html; charset=UTF-8',
      /\.rb$/i => 'text/html; charset=UTF-8',
      /\.pdf$/i => 'application/pdf'
  }
  def content_type_from_path(full_path)
    CONTENT_TYPE_MAP.each do |pat, content_type|
      return content_type if full_path =~ pat
    end
    nil
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
  def site_from_name(name)
    @@n2s ||= build_n2s
    @@n2s[name]
  end
  def build_n2s
    Name2SiteCache.new
  end
  def fix_ext(full_path, ext)
    if full_path =~ /\/([^\/+])$/
      filename = $1
      unless filename.include?('.')
        full_path += ext
      end
    end
    full_path
  end

  def analyze
    namespace = virtualhost_namespace_map[request.host]
#    puts "request.path_info:#{request.path_info}"
    if namespace
      return not_found unless request.path_info =~ /^\/(.+)$/
      path = $1
    else
      return not_found unless request.path_info =~ /^\/([^\/]+)\/(.+)$/
      namespace = $1; path = $2
    end
#    puts "namespace:#{namespace}, path:#{path}"
    return not_found if path =~ /\.html?$/ # skip html
    cc = MongoConnection.class_config['site_filesystem']
    mc = Mongo::Connection.new(cc['host'], cc['port'].to_i)
    db = mc.db(cc['db'])
    gf = GridFile.new(db, namespace)
    if gf.exist?(path)
      gf.open(path) do |gs|
        c = gs.read
        RawMemCache[request.path_info] = c
        return ok({"Content-Type" => gs.content_type}, c)
      end
    elsif (namespace == 'files' && path =~ /^(\d+)\/(.+)$/ || path =~ /^files\/(\d+)\/(.+)$/)
      otid = $1; filename = $2
#      puts "otid:#{otid}, filename:#{filename}"
      gf = GridFile.new(MongoConnection.media_keeper.remote_connection, "ot#{otid}")
      if gf.exist?(filename)
        gf.open(filename) do |gs|
          c = gs.read
          RawMemCache[request.path_info] = c
          return ok({"Content-Type" => gs.content_type}, c)
        end
      end
    end
    not_found
  end
  def virtualhost_namespace_map(opts = {})
    @@vh2n_map ||= VirtualHostNamespaceMap.new(opts).update
  end
  def not_found
    HttpResponse.not_found
  end
  def ok(headers, content)
    HttpResponse.ok(headers, content)
  end
  def process_result(result)
    return nil if result.not_found?
    if result.ok?
      result.headers.each do |key, value|
        response.headers[key] = value
      end
      render :text => result.content
    elsif result.redirect?
      redirect_to result.headers['Location']
    else raise "Unsupported result type for :#{result.status}"
    end
  end
  def redirect_for_root
    # puts "request_path:#{request_path}"
    if request_path =~ /^\/[^\/]+$/
      redirect_to request_path + '/'
      true
    end
  end
  private
  def request_path
    (@uri ||= URI.parse(request.env['REQUEST_URI'])).path
  end
end
