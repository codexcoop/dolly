class OriginalObject < ActiveRecord::Base
  include AutoconfigureEntity

  include Restrictable
  include Trimmer

  include Unimarc
  include UnimarcConfig

  include Countable
  extend  Countable::ClassMethods

  include CustomCounterCachable

  # will_paginate
  class << self
    attr_reader :per_page
  end
  @per_page = 20

  restrict_destroy_if_dependent :digital_objects, :related_original_objects
  trimmed_fields :bid, :isbn, :issn, :string_date

  attr_accessor :dynamic_related_count,
                :dynamic_digital_objects_count

  before_create :compute_uuid

  before_save :mark_changed_bid
  before_save :mark_changed_tmp_unimarc_links
  after_save  :update_unimarc_links
  after_save  :review_and_process_pendent_links

  serialize :tmp_unimarc_links, Hash

  validates_uniqueness_of :identifier
  validates_uniqueness_of :bid, :if => Proc.new{|original_object| original_object.bid.present? }
  validates_uniqueness_of :isbn, :if => Proc.new{|original_object| original_object.isbn.present? }
  validates_uniqueness_of :issn, :if => Proc.new{|original_object| original_object.issn.present? }

  has_many :digital_objects

  belongs_to :institution, :counter_cache => true
  validates_presence_of :institution_id

  validates_presence_of :title

  belongs_to :user
  validates_presence_of :user_id

  @properties = [
    {:cardinality=>"many", :conditions=>{:vocabulary_id=>39, :property_id=>91}, :name=>:object_types},
    {:cardinality=>"many", :conditions=>{:vocabulary_id=>38, :property_id=>92}, :name=>:subjects},
    {:cardinality=>"many", :conditions=>{:vocabulary_id=>34, :property_id=>99}, :name=>:creators},
    {:cardinality=>"many", :conditions=>{:vocabulary_id=>34, :property_id=>90}, :name=>:contributors},
    {:cardinality=>"many", :conditions=>{:vocabulary_id=>36, :property_id=>100}, :name=>:publishers},
    {:cardinality=>"many", :conditions=>{:vocabulary_id=>14, :property_id=>94}, :name=>:languages},
    {:cardinality=>"many", :conditions=>{:vocabulary_id=>33, :property_id=>93}, :name=>:coverages}
  ]

  define_associations_for_properties(@properties)

  # Related original objects
  has_many :unimarc_links, :dependent => :destroy do
    def missing
      find(:all, :include => :linked_original_object).select{|unimarc_link| unimarc_link.missing_linked? }
    end
  end

  has_many :associations_to,
    :class_name => 'Association',
    :foreign_key => :original_object_id,
    :dependent => :destroy

  has_many :related,
    :through => :associations_to,
    :source => :related_original_object do
    def with_qualifier
      find(:all, :include => [:associations_from], :select => "original_objects.*, associations.qualifier")
    end
  end

  belongs_to :main_related,
    :class_name => self.name,
    :foreign_key => :main_related_id

  has_many :main_dependents,
    :class_name => self.name,
    :foreign_key => :main_related_id

  # top_level => original object with related objects which have it as main related
  named_scope :top_level, lambda{|conditions|
    conditions ||= {}
    {
      :select => "DISTINCT original_objects.*",
      :joins => :main_dependents,
      :conditions => {:original_objects => {:main_related_id => nil}}.merge(conditions),
      :order => "original_objects.title"
    }
  }

  def is_top_level?
    self.class.top_level(:original_objects => {:id => self.id}).any?
  end

  def is_not_top_level?
    !is_top_level?
  end

  # stand_alone => original object with no dependents and no main related
  named_scope :stand_alone, lambda{|conditions|
    conditions ||= {}
    {
      :select => "original_objects.*",
      :joins =>  "LEFT OUTER JOIN original_objects AS dependents
                  ON original_objects.id = dependents.main_related_id",
      :conditions => {
        :original_objects => {:main_related_id => nil},
        :dependents => {:main_related_id => nil}
      }.merge(conditions),
      :order => "original_objects.title"
    }
  }

  def is_stand_alone?
    self.class.stand_alone(:original_objects => {:id => self.id}).any?
  end

  def is_not_stand_alone?
    !is_stand_alone?
  end

  # This association is required to be able to destroy the current original object (due to foreign keys)
  # :dependent => :destroy has to be declared
  has_many :associations_from,
    :class_name => 'Association',
    :foreign_key => :related_original_object_id,
    :dependent => :destroy

  accepts_nested_attributes_for :associations_to

  named_scope :related_count, lambda {|*ids|
    {
      :joins => :associations_to,
      :group => "original_objects.id",
      :select => "original_objects.id, COUNT(associations.original_object_id) AS count",
      :conditions => {:original_objects => {:id => [ids].flatten} }
    }
  }

  named_scope :digital_objects_count, lambda {|*ids|
    {
      :joins => :digital_objects,
      :group => "original_objects.id",
      :select => "original_objects.id, COUNT(digital_objects.original_object_id) AS count",
      :conditions => {:original_objects => {:id => [ids].flatten} }
    }
  }

  named_scope :for_user, lambda { |user|
    case user.role.name
    when 'end_user', 'admin'
      {}
    else
      { :joins => :institution, :conditions => {:institutions => {:id => user.institution_id}} }
    end
  }

  named_scope :featured, :conditions => { :featured => true }

  # OPTIMIZE: dynamic counts could be dried up
  def self.set_dynamic_related_count(original_objects)
    related_counts = self.related_count(original_objects.map(&:id))
    original_objects.tap do |collection|
      collection.each do |original_object|
        original_object.dynamic_related_count = (related_counts.select{|count|count.id==original_object.id}.first.try(:count).to_i || 0)
      end
    end
  end

  def self.set_dynamic_digital_objects_count(original_objects)
    digital_objects_counts = self.digital_objects_count(original_objects.map(&:id))
    original_objects.tap do |collection|
      collection.each do |original_object|
        original_object.dynamic_digital_objects_count = (digital_objects_counts.select{|count|count.id==original_object.id}.first.try(:count).to_i || 0)
      end
    end
  end

  include Descriptor

  [:qualifier, :main_association_qualifier].each do |association_qualifier|
    define_description_for_attribute(association_qualifier) do |qualifier, language|
      language ||= :it
      UnimarcConfig::UNIMARC_LINK_FIELDS[qualifier.to_s][:description][language.to_sym]
    end
  end

  # virtual attribute
  def shortened_title(required_length=70)
    if title.to_s.length > required_length
      title[0..(required_length-1)] + '...'
    else
      title
    end
  end

  def publishers_with_string_date
    array = []
    array << publishers.map(&:translation_coalesce).join(' / ')
    array << string_date
    array.delete_if(&:blank?).join(', ')
  end

  def creators_and_contributors
    (creators + contributors).uniq.map(&:translation_coalesce).join(' / ')
  end

  def compute_uuid
    if self.title
      random_uuid_seed = UUID.create_random
      self.identifier = UUID.create_sha1( self.title, random_uuid_seed).to_s
    else
      self.identifier = UUID.create_random
    end
  end

  # properties_has_many, properties_has_one, properties_belongs_to...
  def define_properties_list_method(message)
    association_type = message.to_s.gsub(/^properties_/,'')
    self.class.reflect_on_all_associations(association_type.to_sym).map(&:name)
  end

  def method_missing(message, *args, &block)
    if message.to_s =~ /^properties_/
      define_properties_list_method(message)
    else
      super
    end
  end

  def load_properties_from_db
    Entity.find_by_name(self.class.name).properties
  end

  def property_by_name(prop_name)
    self.class.properties_with_vocabularies_all.select{|prop| prop.name == prop_name.to_s}.first
  end

end

