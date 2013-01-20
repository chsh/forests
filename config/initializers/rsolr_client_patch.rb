
class RSolr::Client
  def query(*args)
    opts = args.extract_options!
    if args.size == 1
      opts[:q] = args[0]
    end
    self.select :data => opts
  end
end
