class CopyDownImportHook
  def self.convert(rows)
    lasts = []
    rows.map do |row|
      row.each_with_index do |cell, index|
        if cell.blank?
          if lasts[index]
            row[index] = lasts[index]
          end
        else
          lasts[index] = cell
          sz = lasts.size
          ni = index + 1
          if ni < sz
            (ni ... sz).each { |ci| lasts[ci] = nil }
          end
        end
      end
    end
  end
end
