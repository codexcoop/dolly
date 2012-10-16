# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20121011022537) do

  create_table "application_languages", :force => true do |t|
    t.string   "code",       :null => false
    t.string   "name",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "application_languages", ["code"], :name => "index_application_languages_on_code"

  create_table "associations", :force => true do |t|
    t.integer  "original_object_id",                      :null => false
    t.integer  "related_original_object_id",              :null => false
    t.string   "qualifier",                  :limit => 3, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "digital_collection_terms", :force => true do |t|
    t.integer  "digital_collection_id", :null => false
    t.integer  "term_id",               :null => false
    t.integer  "vocabulary_id"
    t.integer  "property_id",           :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "digital_collections", :force => true do |t|
    t.string   "identifier",   :null => false
    t.string   "title",        :null => false
    t.text     "description"
    t.text     "database"
    t.integer  "user_id",      :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "project_id"
    t.text     "legal_status"
    t.integer  "start_date"
    t.integer  "end_date"
  end

  add_index "digital_collections", ["identifier"], :name => "index_digital_collections_on_identifier", :unique => true
  add_index "digital_collections", ["title", "project_id"], :name => "index_digital_collections_on_title_and_project_id"
  add_index "digital_collections", ["user_id"], :name => "index_digital_collections_on_user_id"

  create_table "digital_files", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",                                     :null => false
    t.integer  "digital_object_id"
    t.boolean  "technically_valid"
    t.string   "derivative_filename"
    t.string   "original_content_type"
    t.integer  "position"
    t.string   "original_filename"
    t.integer  "original_position"
    t.text     "large_technical_metadata"
    t.integer  "width_small"
    t.integer  "height_small"
    t.integer  "width_large"
    t.integer  "height_large"
    t.boolean  "key_image",                :default => false
  end

  add_index "digital_files", ["digital_object_id", "original_filename"], :name => "index_digital_files_on_digital_object_id_and_original_filename"
  add_index "digital_files", ["digital_object_id"], :name => "index_digital_files_on_digital_object_id"
  add_index "digital_files", ["key_image"], :name => "index_digital_files_on_key_image"
  add_index "digital_files", ["original_filename"], :name => "index_digital_files_on_original_filename"

  create_table "digital_object_terms", :force => true do |t|
    t.integer  "digital_object_id", :null => false
    t.integer  "term_id",           :null => false
    t.integer  "vocabulary_id"
    t.integer  "property_id",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "digital_objects", :force => true do |t|
    t.text     "source"
    t.text     "rights"
    t.text     "unstored"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",                                                :null => false
    t.string   "identifier",            :limit => 36,                    :null => false
    t.integer  "digital_collection_id"
    t.integer  "digital_files_count",                 :default => 0,     :null => false
    t.integer  "original_object_id",                                     :null => false
    t.string   "master_dirpath"
    t.boolean  "completed",                           :default => false, :null => false
    t.integer  "institution_id"
    t.string   "record_type",           :limit => 10
  end

  add_index "digital_objects", ["institution_id"], :name => "index_digital_objects_on_institution_id"
  add_index "digital_objects", ["record_type"], :name => "index_digital_objects_on_record_type"

  create_table "elements", :force => true do |t|
    t.string   "name"
    t.integer  "metadata_standard_id"
    t.string   "section"
    t.text     "section_description"
    t.integer  "entity_id"
    t.string   "cardinality"
    t.string   "requirement"
    t.integer  "position",                  :default => 0, :null => false
    t.string   "datatype"
    t.integer  "vocabulary_id"
    t.string   "human_en"
    t.text     "description_en"
    t.string   "human_it"
    t.text     "description_it"
    t.boolean  "is_user_editable"
    t.integer  "visibility_id"
    t.text     "example"
    t.text     "notes"
    t.text     "italian_version_notes"
    t.text     "official_vocabulary_lists"
    t.text     "other_suggested_lookups"
    t.text     "user_tags"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "property_elements_count",   :default => 0
  end

  create_table "entities", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "entity_metadata_standards", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "entity_id"
    t.integer  "metadata_standard_id", :null => false
  end

  create_table "institution_terms", :force => true do |t|
    t.integer  "institution_id", :null => false
    t.integer  "term_id",        :null => false
    t.integer  "vocabulary_id"
    t.integer  "property_id",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "institutions", :force => true do |t|
    t.string   "name"
    t.string   "url"
    t.string   "address"
    t.string   "phone"
    t.integer  "user_id",                                             :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uuid",                   :limit => 36
    t.integer  "projects_count",                       :default => 0, :null => false
    t.string   "email"
    t.integer  "original_objects_count",               :default => 0
    t.string   "sbn"
  end

  create_table "metadata_standards", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "description"
  end

  create_table "nodes", :force => true do |t|
    t.integer  "digital_object_id"
    t.text     "description",       :null => false
    t.integer  "parent_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position"
    t.integer  "digital_file_id"
  end

  create_table "original_object_people", :force => true do |t|
    t.integer  "original_object_id",                :null => false
    t.integer  "person_id",                         :null => false
    t.string   "dc_element"
    t.string   "unimarc_relator_code", :limit => 3
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "original_object_people", ["dc_element"], :name => "index_original_object_people_on_dc_element"
  add_index "original_object_people", ["original_object_id"], :name => "index_original_object_people_on_original_object_id"
  add_index "original_object_people", ["person_id"], :name => "index_original_object_people_on_person_id"

  create_table "original_object_terms", :force => true do |t|
    t.integer  "original_object_id", :null => false
    t.integer  "term_id",            :null => false
    t.integer  "vocabulary_id"
    t.integer  "property_id",        :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "original_objects", :force => true do |t|
    t.string   "identifier"
    t.text     "title"
    t.text     "description"
    t.text     "rights"
    t.text     "unstored"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",                                                    :null => false
    t.integer  "institution_id"
    t.string   "bid"
    t.string   "isbn"
    t.string   "issn"
    t.string   "string_date"
    t.text     "physical_description"
    t.text     "tmp_unimarc_links"
    t.string   "main_association_qualifier", :limit => 3
    t.string   "main_related_title"
    t.integer  "main_related_id"
    t.boolean  "featured",                                :default => false
  end

  add_index "original_objects", ["featured"], :name => "index_original_objects_on_featured"
  add_index "original_objects", ["main_related_id"], :name => "index_original_objects_on_main_related_id"

  create_table "people", :force => true do |t|
    t.string   "source",     :default => "NA", :null => false
    t.string   "identifier", :default => "NA", :null => false
    t.string   "name"
    t.string   "rule",       :default => "NA", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "term_id"
  end

  add_index "people", ["source", "identifier", "name", "rule"], :name => "unique_source_identifier_name_rule", :unique => true

  create_table "project_terms", :force => true do |t|
    t.integer  "project_id",    :null => false
    t.integer  "term_id",       :null => false
    t.integer  "vocabulary_id"
    t.integer  "property_id",   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "projects", :force => true do |t|
    t.string   "identifier",             :limit => 36, :null => false
    t.string   "title",                                :null => false
    t.string   "acronym"
    t.text     "description"
    t.string   "email"
    t.string   "url"
    t.date     "start_date"
    t.date     "completion_date"
    t.integer  "user_id",                              :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "institution_id"
    t.string   "start_date_format",      :limit => 3
    t.string   "completion_date_format", :limit => 3
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.integer  "logo_file_size"
    t.datetime "logo_updated_at"
  end

  add_index "projects", ["identifier"], :name => "index_projects_on_identifier", :unique => true
  add_index "projects", ["title"], :name => "index_projects_on_title", :unique => true
  add_index "projects", ["user_id"], :name => "index_projects_on_user_id"

  create_table "properties", :force => true do |t|
    t.string  "section",         :limit => nil
    t.string  "human_en",        :limit => nil
    t.text    "notes"
    t.text    "description_en"
    t.string  "datatype"
    t.integer "entity_id"
    t.string  "human_it"
    t.text    "description_it"
    t.string  "name"
    t.string  "requirement"
    t.integer "visibility_id"
    t.integer "vocabulary_id"
    t.integer "position",                       :default => 0,    :null => false
    t.string  "cardinality"
    t.string  "form_field_type"
    t.string  "order_terms_by"
    t.boolean "in_use",                         :default => true
  end

  create_table "property_elements", :force => true do |t|
    t.integer  "property_id", :null => false
    t.integer  "element_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "property_elements", ["property_id", "element_id"], :name => "index_property_elements_on_property_id_and_element_id", :unique => true

  create_table "roles", :force => true do |t|
    t.string   "name",             :null => false
    t.integer  "permission_level", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["permission_level"], :name => "index_roles_on_weight", :unique => true

  create_table "swap_digital_files", :id => false, :force => true do |t|
    t.integer  "id",                       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "digital_object_id"
    t.boolean  "technically_valid"
    t.string   "derivative_filename"
    t.string   "original_content_type"
    t.integer  "position"
    t.string   "original_filename"
    t.integer  "original_position"
    t.text     "large_technical_metadata"
    t.integer  "width_small"
    t.integer  "height_small"
    t.integer  "width_large"
    t.integer  "height_large"
  end

  create_table "terms", :force => true do |t|
    t.string   "code"
    t.boolean  "is_native",                        :default => false, :null => false
    t.boolean  "is_approved",                      :default => false, :null => false
    t.integer  "user_id"
    t.integer  "proposer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "vocabulary_id"
    t.string   "uuid",               :limit => 36,                    :null => false
    t.string   "it"
    t.string   "en"
    t.integer  "entity_terms_count",               :default => 0
    t.integer  "position"
    t.boolean  "visible",                          :default => true
  end

  add_index "terms", ["code"], :name => "index_terms_on_code"
  add_index "terms", ["proposer_id"], :name => "index_terms_on_proposer_id"
  add_index "terms", ["user_id"], :name => "index_terms_on_user_id"

  create_table "unimarc_links", :force => true do |t|
    t.integer  "original_object_id",              :null => false
    t.string   "bid",                             :null => false
    t.text     "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "qualifier",          :limit => 3, :null => false
  end

  add_index "unimarc_links", ["bid"], :name => "index_unimarc_links_on_bid"

  create_table "users", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "login",             :null => false
    t.string   "email",             :null => false
    t.string   "crypted_password",  :null => false
    t.string   "password_salt",     :null => false
    t.string   "persistence_token", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "institution_id"
    t.integer  "role_id"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["login"], :name => "index_users_on_login", :unique => true

  create_table "vocabularies", :force => true do |t|
    t.string   "name",                                              :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_user_editable",               :default => false
    t.integer  "terms_count",                    :default => 0,     :null => false
    t.text     "description_it"
    t.text     "description_en"
    t.string   "human_it"
    t.string   "human_en"
    t.string   "uuid",             :limit => 36,                    :null => false
  end

  add_index "vocabularies", ["name"], :name => "index_vocabularies_on_name"

end
