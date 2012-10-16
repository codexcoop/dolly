class Institution < ActiveRecord::Base
  include Restrictable
  include CustomCounterCachable
  include CommonValidations

  restrict_destroy_if_dependent :original_objects,
                                :projects,
                                :users

  before_create :compute_uuid

  def compute_uuid
    random_uuid_seed = UUID.create_random
    self.uuid ||= UUID.create_sha1( self.name, random_uuid_seed).to_s
  end

  default_scope :order => :name

  has_many :users
  has_many :projects
  has_many :original_objects
  has_many :digital_objects

  def digital_collections_count
    DigitalCollection.count(:conditions => {:project_id => self.project_ids}).to_i
  end

  def digital_objects_count
    DigitalObject.count(:conditions => {:digital_collection_id => self.projects.map(&:digital_collection_ids).flatten}).to_i
  end

  validates_presence_of :email
  # TODO: use the built in ":allow_blank" option
  validate_format_if_present :email, :with => :simple_email_regexp # see CommonRegexp module in /lib
  validate_format_if_present :url, :with => :simple_url_regexp # see CommonRegexp module in /lib

  validates_presence_of :address
  validates_presence_of :name
  validates_presence_of :phone

  alias_method :institution_id, :id # a convenience method for authorization methods

  def self.perform_force_counter_cache_reset
    self.force_counter_cache_reset  :original_objects_count => :original_objects,
                                    :projects_count => :projects
  end

end

