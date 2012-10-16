class DigitalObject < ActiveRecord::Base
  include AutoconfigureEntity
  include Restrictable
  include Countable
  extend  Countable::ClassMethods
  include CustomCounterCachable
  include Ingestable

  RECORD_TYPES = ['TEXT', 'IMAGE', 'SOUND', 'VIDEO']

 # NOTE: "the column 'type' is reserved for storing the class in case of inheritance",
 # ma un attributo denominato "type" ci serve per Mets / Europeana.
 alias_attribute :type, :record_type

  # will_paginate
  class << self
    attr_reader :per_page
  end
  @per_page = 20

  attr_accessor :processing_in_progress, # FIXME: deprecated
                :filetype,
                :original_single_file_path,
                :original_content_type,
                :available_digital_files_count, # FIXME: deprecated
                :bookreadable,
                :pendent_ingest, # FIXME: deprecated
                :content_type

  alias :bookreadable? :bookreadable
  alias :pendent_ingest? :pendent_ingest

  attr_reader   :thumbnail_url,
                :is_shown_at,
                :is_shown_by,
                :provider

  after_save :initialize_virtual_attributes

  restrict_destroy_if_dependent :digital_files

  before_create :compute_uuid

  after_create :create_toc_node

  def create_toc_node
    toc = self.create_toc(:description => 'Sommario') unless self.toc
  end

  def compute_uuid
    self.identifier = UUID.create_random.to_s
  end

  def no_processing_in_progress
    !self.processing_in_progress
  end

  def assets_dir
    path = File.join(DIGITAL_FILES_DIR, institution_id.to_s, id.to_s)
    File.exist?(path) ? path : nil
  end

  def digital_files_absolute_path(opts={})
    opts.assert_required_keys(:variant)
    path = File.join(assets_dir.to_s, opts[:variant].to_s)
    File.exist?(path) ? path.sub(/\A#{File.join(RAILS_ROOT, 'public')}/,'') :  nil
  end

  Struct.new("UrlLike", :requires_hostaddress_from_request, :absolute_path)

  # FIXME: fix redefinition of Struct
  # TODO: simplify simplify simplify
  def initialize_thumbnail_url
    @thumbnail_url = Struct::UrlLike.new(true, self.digital_files.first.absolute_path(:variant => 'S')) if self.digital_files.any?
  end

  def initialize_is_shown_at
    @is_shown_at = Struct::UrlLike.new(true, "/#{self.class.name.tableize}/#{self.id}")
  end

  def initialize_is_shown_by
    @is_shown_by = Struct::UrlLike.new(true, "#{self.is_shown_at.absolute_path}/browse")
  end

  def initialize_provider
    @provider = "Biblioteca Digitale della Lombardia"
  end

  def thumbnail_url
    send(:"initialize_#{__method__.to_s}")
  end

  def is_shown_at
    send(:"initialize_#{__method__.to_s}")
  end

  def is_shown_by
    send(:"initialize_#{__method__.to_s}")
  end

  def provider
    send(:"initialize_#{__method__.to_s}")
  end

  def initialize_virtual_attributes
    initialize_thumbnail_url
    initialize_is_shown_at
    initialize_is_shown_by
    initialize_provider
  end

  # Associations
  # OPTIMIZE: valutare se puà bastare una sola delle due associazioni (con user e institution) ?
  belongs_to :user
  belongs_to :institution
  belongs_to :digital_collection
  belongs_to :original_object

  has_many :digital_files, :dependent => :destroy, :order => 'position'
  has_one :toc, :class_name => 'Node',
    :conditions => {:parent_id => nil}, :dependent => :destroy, :autosave => true
  has_many :nodes, :dependent => :destroy, :autosave => true, :order => 'parent_id, position'
  has_one :key_image, :class_name => 'DigitalFile',
    :conditions => {:key_image => true},
    :readonly => true

  # Validations
  validates_presence_of :user_id
  validates_presence_of :institution_id
  validates_presence_of :digital_collection_id
  validates_presence_of :original_object_id
  validates_presence_of :record_type

  def digital_files_paths(options={})
    options.assert_required_keys(:variant)
    institution_id = self.institution_id
    self.digital_files.find(:all, :select => "id, derivative_filename, digital_object_id").map do |digital_file|
      {
        :id => digital_file.id,
        :absolute_path => digital_file.absolute_path(:institution_id => institution_id,
                                                     :variant => options[:variant])
      }
    end
  end

  def title
    @title ||= self.original_object.title
  end

  def nodes_without_toc
    self.nodes.find(:all, :conditions => 'parent_id IS NOT NULL')
  end

  def project_id
    digital_collection.project_id if digital_collection
  end

  # query-intensive
  def nodes_to_jstree_hash
    self.toc.descendants_to_jstree_hash
  end

  def restore_positions
    success = true
    DigitalFile.transaction do
      self.digital_files.each do |digital_file|
        success = digital_file.update_attributes(:position => digital_file.original_position)
      end
    end
    success
  end

  # first parameter (optional): a user
  # second parameter (mandatory): request params hash, :digital_collection_id, :original_object_id, :project_id and :institution_id are extracted when present
  # third parameter (mandatory): a string for order clause, complete of direction if needed
  # rest of the parameters: other query conditions (any syntax accepted by active record)
  named_scope :custom_search, lambda{|*args|
    admin             = Role.find_by_name('admin')
    end_user          = Role.find_by_name('end_user')

    user              = args.first.kind_of?(User) ? args.shift : nil
    params            = args.shift
    order             = args.shift
    search_conditions = args
    [:digital_collection_id, :original_object_id, :project_id, :institution_id].each do |param_key|
      if params && params[param_key].present?
        search_conditions << ["#{param_key.to_s.gsub(/_id\Z/,'').tableize}.id = ?", params[param_key]]
      end
    end
    search_conditions << ["institutions.id = ?", user.institution_id] if user && (user > end_user && user < admin)

    {
      :select => "digital_objects.id,
                  digital_objects.original_object_id,
                  digital_objects.digital_files_count,
                  digital_objects.completed,
                  digital_objects.updated_at,
                  digital_objects.digital_collection_id,
                  digital_objects.institution_id,
                  original_objects.title AS original_object_title,
                  original_objects.main_related_title AS original_object_main_related_title,
                  original_objects.string_date AS original_object_string_date,
                  digital_collections.title AS digital_collection_title,
                  institutions.name AS institution_name,
                  COALESCE(original_objects.main_related_title || original_objects.title, original_objects.title) AS ordering_title",
      :joins => " INNER JOIN digital_collections ON digital_collections.id = digital_objects.digital_collection_id
                  INNER JOIN institutions ON institutions.id = digital_objects.institution_id
                  LEFT OUTER JOIN original_objects ON digital_objects.original_object_id = original_objects.id",
      :include => :key_image,
      :conditions => merge_conditions(*search_conditions),
      :order => order
    }
  }

  named_scope :status, lambda { |status|
    conditions =  case status
                  when 'draft', false, 'false'
                    "digital_objects.digital_files_count = 0 OR digital_objects.completed = FALSE"
                  when 'complete', true, 'true'
                    "digital_objects.digital_files_count > 0 AND digital_objects.completed = TRUE"
                  else
                    {}
                  end
    {:conditions => conditions}
  }

  named_scope :for_user, lambda { |user|
    case user.role.name
    when 'end_user', 'admin'
      {}
    else
      { :conditions => {:institution_id => user.institution_id} }
    end
  }

  def self.count_by_status
    group = "CASE WHEN digital_files_count IS NOT NULL AND digital_files_count > 0 AND completed = TRUE THEN 'complete' ELSE 'draft' END"
    count('id', :group => group).tap do |results|
      results['all'] = results.values.sum
    end
  end

  def self.perform_force_counter_cache_reset
    self.force_counter_cache_reset :digital_files_count => :digital_files
  end

  def self.total_digital_files_count(*digital_object_ids)
    DigitalFile.outer_digital_objects_count(
      ["digital_objects.id IN (?)", [digital_object_ids].flatten]
    )
  end

end

