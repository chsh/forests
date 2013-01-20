class TraversalSearchExporter
  def initialize(one_table)
    @one_table = OneTable.find one_table # it causes error automatically.
    @tso = TraversalSearchOption.find_by_one_table_id @one_table.id
    raise "Traversal Search Options not found." unless @tso
  end
  def export(data_file_path, options_file_path)
    export_options(options_file_path)
    export_data(data_file_path)
  end

  private
  def export_options(options_file_path)
    if options_file_path.is_a?(IO)
      YAML.dump(@tso.options, options_file_path)
    else
      File.open(options_file_path, 'w') do |w|
        YAML.dump(@tso.options, w)
      end
    end
  end
  def export_data(data_file_path)
    if data_file_path.is_a?(IO)
      @one_table.rows.each do |row|
#        puts "row:#{row}"
        row = row.map { |cell| cell.to_s.gsub(/[\t\n]+/, ' ') }
        data_file_path.puts row.join("\t")
      end
    else
      File.open(data_file_path, 'w') do |w|
        @one_table.rows.each do |row|
  #        puts "row:#{row}"
          row = row.map { |cell| cell.to_s.gsub(/[\t\n]+/, ' ') }
          w.puts row.join("\t")
        end
      end
    end
  end
end
