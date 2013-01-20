# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120824092323) do

  create_table "activities", :force => true do |t|
    t.integer  "user_id"
    t.string   "target_type"
    t.integer  "target_id"
    t.string   "action"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.integer  "one_table_id"
  end

  add_index "activities", ["one_table_id"], :name => "index_activities_on_one_table_id"
  add_index "activities", ["target_type", "target_id"], :name => "index_activities_on_target_type_and_target_id"
  add_index "activities", ["user_id"], :name => "index_activities_on_user_id"

  create_table "admin_options", :force => true do |t|
    t.string   "attachable_type"
    t.integer  "attachable_id"
    t.text     "attrs"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "admin_options", ["attachable_type", "attachable_id"], :name => "index_admin_options_on_attachable_type_and_attachable_id"

  create_table "block_contents", :force => true do |t|
    t.integer  "block_id",     :null => false
    t.string   "content_type"
    t.text     "content"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "block_contents", ["block_id", "content_type"], :name => "index_block_contents_on_block_id_and_content_type", :unique => true

  create_table "block_one_table_headers", :force => true do |t|
    t.integer  "block_id",            :null => false
    t.integer  "one_table_header_id", :null => false
    t.integer  "sort_index",          :null => false
    t.text     "options"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
  end

  add_index "block_one_table_headers", ["block_id", "sort_index"], :name => "index_block_one_table_headers_on_block_id_and_sort_index"
  add_index "block_one_table_headers", ["one_table_header_id"], :name => "index_block_one_table_headers_on_one_table_header_id"

  create_table "blocks", :force => true do |t|
    t.integer  "user_id"
    t.integer  "one_table_id"
    t.integer  "site_id"
    t.string   "name"
    t.integer  "kind"
    t.string   "conditions"
    t.string   "order"
    t.string   "limit"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "blocks", ["site_id", "name"], :name => "index_blocks_on_site_id_and_name", :unique => true
  add_index "blocks", ["user_id", "one_table_id"], :name => "index_blocks_on_user_id_and_one_table_id"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "exception_keepers", :force => true do |t|
    t.string   "keepable_type", :null => false
    t.integer  "keepable_id",   :null => false
    t.string   "class_name",    :null => false
    t.text     "message",       :null => false
    t.text     "backtrace",     :null => false
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "exception_keepers", ["keepable_type", "keepable_id"], :name => "index_exception_keepers_on_keepable_type_and_keepable_id"

  create_table "formulas", :force => true do |t|
    t.integer  "one_table_header_id", :null => false
    t.string   "type"
    t.text     "params"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
  end

  create_table "logged_word_search_activities", :force => true do |t|
    t.integer  "logged_word_id"
    t.integer  "search_activity_id"
    t.datetime "stamped_at"
  end

  add_index "logged_word_search_activities", ["logged_word_id", "search_activity_id", "stamped_at"], :name => "index_lwsa_on_lw_and_sa_and_s"

  create_table "logged_words", :force => true do |t|
    t.integer  "site_id",                                            :null => false
    t.string   "value",                                              :null => false
    t.integer  "logged_word_search_activities_count", :default => 0
    t.datetime "created_at",                                         :null => false
    t.datetime "updated_at",                                         :null => false
  end

  add_index "logged_words", ["site_id", "logged_word_search_activities_count"], :name => "index_logged_words_on_site_and_lwsac"
  add_index "logged_words", ["site_id", "value"], :name => "index_logged_words_on_site_id_and_value", :unique => true

  create_table "model_comments", :force => true do |t|
    t.string   "commentable_type", :null => false
    t.integer  "commentable_id",   :null => false
    t.text     "content"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  add_index "model_comments", ["commentable_type", "commentable_id"], :name => "index_model_comments_on_commentable_type_and_commentable_id"

  create_table "mongo_attachments", :force => true do |t|
    t.integer  "user_id",         :null => false
    t.integer  "attachable_id"
    t.string   "attachable_type"
    t.string   "filename"
    t.string   "content_type"
    t.integer  "size"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "mongo_attachments", ["attachable_type", "attachable_id", "filename"], :name => "index_mas_attachable_type_id_and_filename", :unique => true
  add_index "mongo_attachments", ["user_id"], :name => "index_mongo_attachments_on_user_id"

  create_table "mongo_connections", :force => true do |t|
    t.string   "name",                     :null => false
    t.string   "host",                     :null => false
    t.string   "port",                     :null => false
    t.string   "db",                       :null => false
    t.string   "sha",        :limit => 40, :null => false
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
  end

  create_table "one_table_headers", :force => true do |t|
    t.integer  "one_table_id",                    :null => false
    t.string   "label"
    t.string   "sysname"
    t.string   "refname"
    t.integer  "kind"
    t.integer  "index"
    t.boolean  "multiple",     :default => false
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.boolean  "primary_key",  :default => false
  end

  add_index "one_table_headers", ["one_table_id", "index"], :name => "index_one_table_headers_on_one_table_id_and_index"

  create_table "one_table_hooks", :force => true do |t|
    t.integer  "one_table_id", :null => false
    t.string   "on",           :null => false
    t.text     "code",         :null => false
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "one_table_hooks", ["one_table_id", "on"], :name => "index_one_table_hooks_on_one_table_id_and_on"

  create_table "one_table_template_one_table_headers", :force => true do |t|
    t.integer  "one_table_template_id"
    t.integer  "one_table_header_id"
    t.boolean  "used",                  :default => false
    t.integer  "index"
    t.string   "query"
    t.string   "label"
    t.datetime "created_at",                               :null => false
    t.datetime "updated_at",                               :null => false
    t.integer  "display_index"
  end

  add_index "one_table_template_one_table_headers", ["display_index"], :name => "index_one_table_template_one_table_headers_on_display_index"
  add_index "one_table_template_one_table_headers", ["one_table_template_id", "index"], :name => "index_ottoth_on_ott_and_index"
  add_index "one_table_template_one_table_headers", ["one_table_template_id", "one_table_header_id"], :name => "index_ottoth_on_ott_and_oth", :unique => true

  create_table "one_table_templates", :force => true do |t|
    t.integer  "one_table_id"
    t.integer  "user_id"
    t.string   "name"
    t.integer  "output_format"
    t.string   "output_encoding"
    t.integer  "output_lf"
    t.text     "attrs"
    t.string   "query"
    t.string   "sort"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "one_table_templates", ["one_table_id"], :name => "index_one_table_templates_on_one_table_id"
  add_index "one_table_templates", ["user_id"], :name => "index_one_table_templates_on_user_id"

  create_table "one_tables", :force => true do |t|
    t.integer  "user_id",                      :null => false
    t.string   "name",                         :null => false
    t.string   "status"
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
    t.boolean  "is_public",  :default => true
  end

  add_index "one_tables", ["is_public"], :name => "index_one_tables_on_is_public"
  add_index "one_tables", ["user_id", "name"], :name => "index_one_tables_on_user_id_and_name", :unique => true

  create_table "owner_users", :force => true do |t|
    t.integer  "owner_id",   :null => false
    t.integer  "user_id",    :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "owner_users", ["owner_id"], :name => "index_owner_users_on_owner_id"
  add_index "owner_users", ["user_id"], :name => "index_owner_users_on_user_id"

  create_table "pages", :force => true do |t|
    t.integer  "site_id",                             :null => false
    t.string   "name"
    t.text     "editable_content",                    :null => false
    t.text     "internal_content"
    t.string   "path_regexp"
    t.string   "block_keys"
    t.string   "url_keys"
    t.boolean  "published"
    t.string   "language"
    t.boolean  "keyword_logging",  :default => false
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
  end

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "roles", ["name", "resource_type", "resource_id"], :name => "index_roles_on_name_and_resource_type_and_resource_id"
  add_index "roles", ["name"], :name => "index_roles_on_name"

  create_table "search_activities", :force => true do |t|
    t.integer  "site_id",    :null => false
    t.datetime "stamped_at", :null => false
  end

  add_index "search_activities", ["site_id", "stamped_at"], :name => "index_search_activities_on_site_id_and_stamped_at"

  create_table "search_word_lists", :force => true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "search_word_lists", ["user_id", "name"], :name => "index_search_word_lists_on_user_id_and_name", :unique => true

  create_table "search_words", :force => true do |t|
    t.integer  "search_word_list_id"
    t.integer  "index"
    t.string   "display_value"
    t.string   "search_value"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
  end

  add_index "search_words", ["search_word_list_id", "index"], :name => "index_search_words_on_search_word_list_id_and_index", :unique => true

  create_table "site_attributes", :force => true do |t|
    t.integer  "site_id",    :null => false
    t.string   "key"
    t.string   "value"
    t.text     "metadata"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "site_attributes", ["site_id", "key"], :name => "index_site_attributes_on_site_id_and_key", :unique => true

  create_table "site_files", :force => true do |t|
    t.integer  "site_id",                       :null => false
    t.string   "path",                          :null => false
    t.string   "parent_id"
    t.boolean  "folder",     :default => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  add_index "site_files", ["parent_id"], :name => "index_site_files_on_parent_id"
  add_index "site_files", ["site_id", "path"], :name => "index_site_files_on_site_id_and_path", :unique => true

  create_table "sites", :force => true do |t|
    t.integer  "user_id",                            :null => false
    t.string   "name"
    t.text     "site_attributes"
    t.string   "virtualhost"
    t.boolean  "clonable",        :default => false
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
  end

  add_index "sites", ["name"], :name => "index_sites_on_name", :unique => true
  add_index "sites", ["user_id"], :name => "index_sites_on_user_id"
  add_index "sites", ["virtualhost"], :name => "index_sites_on_virtualhost", :unique => true

  create_table "solr_connections", :force => true do |t|
    t.string   "name",                     :null => false
    t.string   "url",                      :null => false
    t.text     "options"
    t.string   "sha",        :limit => 40, :null => false
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
  end

  create_table "traversal_search_options", :force => true do |t|
    t.integer  "one_table_id", :null => false
    t.text     "options"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "traversal_search_options", ["one_table_id"], :name => "index_traversal_search_options_on_one_table_id"

  create_table "user_model_permissions", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.string   "model_type", :null => false
    t.integer  "model_id"
    t.integer  "flags"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "user_model_permissions", ["flags"], :name => "index_user_model_permissions_on_flags"
  add_index "user_model_permissions", ["model_type", "model_id"], :name => "index_user_model_permissions_on_model_type_and_model_id"
  add_index "user_model_permissions", ["user_id"], :name => "index_user_model_permissions_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "email",                  :default => ""
    t.string   "encrypted_password",     :default => "",    :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "api_public_token"
    t.string   "api_secret_token"
    t.boolean  "active",                 :default => true,  :null => false
    t.boolean  "admin",                  :default => false, :null => false
    t.integer  "level",                  :default => 0
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.string   "login",                                     :null => false
  end

  add_index "users", ["login"], :name => "index_users_on_login", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "users_roles", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  add_index "users_roles", ["user_id", "role_id"], :name => "index_users_roles_on_user_id_and_role_id"

end
