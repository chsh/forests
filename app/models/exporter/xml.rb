class Exporter::XML
  def export(headers, records, opts = {})
    opts.assert_valid_keys :id_url_base
    doc = Nokogiri::XML::Document.new("1.0")
    doc.encoding = 'UTF-8'
    root = doc.create_element('root')
    elm_headers = doc.create_element('headers')
    # initially setup header used by ID.
    attrs = {
            :label => 'ID',
            :multiple => '0',
            :type => 'String'
    }
    elm_h = crelm(doc, 'header', attrs)
    elm_headers << elm_h
    attrs = {
            :label => 'URL',
            :multiple => '0',
            :type => 'String'
    }
    elm_h = crelm(doc, 'header', attrs)
    elm_headers << elm_h
    headers.each do |h|
      attrs = {
              :label => h.label,
              :refname => h.refname,
              :sysname => h.sysname,
              :multiple => (h.multiple? ? '1' : '0'),
              :type => h.kind_as_string
      }
      attrs[:link_key] = content_value_from_header(h, 'link_key')
      elm_h = crelm(doc, 'header', attrs)
      elm_headers << elm_h
    end
    elm_rows = crelm(doc, 'rows', :num_rows => records.size)
    records.each do |r|
      # 1. Append ID column.
      elm_row = crelm(doc, 'row')
      elm_col = crelm(doc, 'col', :id => '1')
      elm_colv = crelm(doc, 'value')
      elm_colv << doc.create_text_node(r.id.to_s)
      elm_col << elm_colv
      elm_row << elm_col
      # 2. Append URL column.
      elm_col = crelm(doc, 'col')
      elm_colv = crelm(doc, 'value')
      url = opts[:id_url_base].gsub(/\#/, r.id.to_s)
      elm_colv << doc.create_text_node(url)
      elm_col << elm_colv
      elm_row << elm_col
      headers.each do |h|
        col = r[h.sysname]
        if h.multiple?
          if col
            if col.is_a? Array
              vs = col
            else
              vs = [col]
            end
            elm_col = crelm(doc, 'col', :multiple => '1', :size => vs.size)
            vs.each do |v|
              elm_colv = crelm(doc, 'value')
              elm_colv << doc.create_text_node(v)
              elm_col << elm_colv
            end
          else
            elm_col = crelm(doc, 'col', :multiple => '1', :size => 0)
          end
        else
          elm_col = crelm(doc, 'col')
          elm_colv = crelm(doc, 'value')
          elm_colv << doc.create_text_node(col)
          elm_col << elm_colv
        end
        elm_row << elm_col
      end
      elm_rows << elm_row
    end
    root << elm_headers
    root << elm_rows
    root.to_xml :encoding => 'UTF-8'
  end
  private
  def crelm(doc, name, attrs = {})
    elm = doc.create_element(name)
    attrs.each do |key, value|
      elm[key.to_s] = value.to_s
    end
    elm
  end
  def content_value_from_header(header, key)
    return nil unless header.comment
    header.comment[key]
  end
end
