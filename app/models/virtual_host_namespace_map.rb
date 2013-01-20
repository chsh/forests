
class VirtualHostNamespaceMap
  class Timer
    def initialize(interval)
      @interval = interval
      @next_check_time = Time.now
      reset_next
    end
    def if_over
      return unless over?
      if block_given?
        yield
        reset_next
      end
    end
    def over?
      if @next_check_time < Time.now
        true
      else
        false
      end
    end
    private
    def reset_next
      @next_check_time = @next_check_time + @interval
    end
  end
  def initialize(opts = {})
    opts.reverse_merge! :update_interval => 900
    @vh2ns = nil
    @timer = Timer.new(opts[:update_interval])
  end
  def update(force_reload = false)
    if force_reload
      @vh2ns = build_map
    else
      if @vh2ns
        refresh_map
      else
        @vh2ns = build_map
      end
    end
    self
  end
  def [](virtualhost)
    namespace_for virtualhost
  end
  def namespace_for(virtualhost)
    @vh2ns[virtualhost] ||= lookup_name_for_virtualhost(virtualhost)
  end
  def refresh_map
    @timer.if_over do
      @vh2ns = build_map
    end
  end
  private
  def lookup_name_for_virtualhost(virtualhost)
    Site.lookup_name_for_virtualhost(virtualhost)
  end
  def build_map
    h = {}
    Site.all(:conditions => 'virtualhost is not null',
             :select => 'virtualhost, name, updated_at').each do |site|
      h[site.virtualhost] = site.name
    end
    h
  end
end
