# encoding: UTF-8
class OneTableHeaderValue
  FREEWORD_SEARCH = OneTableHeader.find_or_create_by_sysname :sysname => 'ht', :label => 'フリーワード',
                                                             :one_table_id => 0
end
