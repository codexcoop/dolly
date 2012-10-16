class DigitalCollection < ActiveRecord::Base
  include AutoconfigureEntity
  include Restrictable
  include Countable
  extend  Countable::ClassMethods

  restrict_destroy_if_dependent :digital_objects

  before_create :compute_uuid

  def compute_uuid
    random_uuid_seed = UUID.create_random
    self.identifier = UUID.create_sha1( self.title, random_uuid_seed).to_s
  end

  belongs_to :project
  validates_presence_of :project_id

  validates_presence_of :legal_status
  validates_presence_of :description

  def institution_id
    self.project.institution_id if self.project
  end

  def title_with_project(given_size=nil)
    "#{title.size > 70 ? title[0..(given_size || 69)] + '...' : title} / #{project.acronym}"
  end

  has_many :digital_objects

  @properties = [
    {:cardinality=>"many", :conditions=>{:vocabulary_id=>37, :property_id=>4}, :name=>:languages},  #
    {:cardinality=>"many", :conditions=>{:vocabulary_id=>9, :property_id=>5}, :name=>:digital_formats},  #
    {:cardinality=>"many", :conditions=>{:vocabulary_id=>10, :property_id=>6}, :name=>:digital_types},  #
    {:cardinality=>"many", :conditions=>{:vocabulary_id=>6, :property_id=>7}, :name=>:content_types},  #
    {:cardinality=>"many", :conditions=>{:vocabulary_id=>31, :property_id=>14}, :name=>:subjects},  #
    {:cardinality=>"many", :conditions=>{:vocabulary_id=>17, :property_id=>16}, :name=>:periods},
    {:cardinality=>"many", :conditions=>{:vocabulary_id=>29, :property_id=>15}, :name=>:spatial_coverages},
    {:cardinality=>"many", :conditions=>{:vocabulary_id=>5, :property_id=>19}, :name=>:civilisations},
    {:cardinality=>"many", :conditions=>{:vocabulary_id=>44, :property_id=>142}, :name=>:accrual_policies},
    {:cardinality=>"many", :conditions=>{:vocabulary_id=>45, :property_id=>141}, :name=>:accrual_methods},  #
    {:cardinality=>"many", :conditions=>{:vocabulary_id=>46, :property_id=>143}, :name=>:accrual_periodicities},
    {:cardinality=>"many", :conditions=>{:vocabulary_id=>30, :property_id=>10}, :name=>:standards}
  ]

  define_associations_for_properties(@properties)

  validates_presence_of :title
  validates_uniqueness_of :title, :scope => [:project_id]

  validates_numericality_of :start_date, :only_integer => true, :greater_than => 0, :less_than => Time.now.year, :allow_nil => true

  validate :end_date_greater_than_start_date

  private

  # OPTIMIZE: put this type of methods in a lib(see also project model)
  def end_date_greater_than_start_date
    if end_date.present? && start_date.present? && end_date < start_date
      errors.add :start_date, I18n.t(:prior_to_end_date, :scope => [:activerecord, :errors, :messages])
      errors.add :end_date, I18n.t(:greater_than_start_date, :scope => [:activerecord, :errors, :messages])
    end
  end

end

