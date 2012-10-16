class Term < ActiveRecord::Base
  include Restrictable
  include CustomCounterCachable

  ENTITY_TERM_MODEL_NAMES = %W(DigitalCollection DigitalObject OriginalObject Project DigitalFile)

  acts_as_list :scope => :vocabulary_id

  attr_accessor :property_id

  restrict_destroy_if_dependent :digital_collections,
                                :digital_objects,
                                :original_objects,
                                :projects,
                                :digital_files

  restrict_destroy_if_restrictable_by_nature :flag_fields => 'is_native'

  belongs_to :vocabulary, :counter_cache => :terms_count # or 'true'

  before_create :compute_uuid

  # after_save :update_terms_count_in_vocabularies
  #      def update_terms_count_in_vocabularies
  #        Vocabulary.update_counters self.vocabulary_id, :terms_count => 1
  #      end

  belongs_to :vocabulary, :counter_cache => true
  validates_presence_of :vocabulary_id
  belongs_to :user
  #  validates_presence_of :user_id

  validates_presence_of :it
  validates_uniqueness_of :it, :scope => :vocabulary_id

  ENTITY_TERM_MODEL_NAMES.each do |model_name|
    has_many  "#{model_name.tableize.singularize}_terms".to_sym, :dependent => :destroy
    has_many model_name.tableize.to_sym,  :through => "#{model_name.tableize.singularize}_terms".to_sym
  end

  named_scope :autocomplete_search, lambda {|params|
    {
      :select => "id, it AS value, code, it",
      :conditions => ["visible = ? AND vocabulary_id = ? AND LOWER(it) LIKE ?",
                      true, params['vocabulary_id'], "%#{params['term'].downcase}%" ],
      :order => 'position',
      :limit => 7
    }
  }

  def translation_coalesce
    self.it || self.en || self.code
  end

  private

  def code_not_empty_string
    unless code and code.length > 0
      errors.add(:code, ": can't be and empty string.")
    end
  end

  def fill_code_if_missing
    self.code = (self.it or self.en).custom_normalize if self.code.blank? and (self.it or self.en).present?
  end

  def normalize_code
    normalizable_code = self.code || fill_code_if_missing
    if normalizable_code and not normalizable_code.match()
      self.code = normalizable_code.custom_normalize
    end
  end

  def compute_uuid
    random_uuid_seed = UUID.create_random
    self.uuid = UUID.create_sha1( self.vocabulary_id.to_s + self.code.to_s, random_uuid_seed).to_s
  end

  def self.perform_force_counter_cache_reset
    ENTITY_TERM_MODEL_NAMES.each do |model_name|
      self.force_counter_cache_reset  :entity_terms_count => "#{model_name.tableize.singularize}_terms".to_sym
    end
  end

  def self.scope_for_vocabulary_id(vocabulary_id, conditions={})
    {:conditions => {:vocabulary_id => vocabulary_id}.merge(conditions), :order => 'position'}
  end

  named_scope :object_types,            scope_for_vocabulary_id(39)
  named_scope :subjects,                scope_for_vocabulary_id(38)
  named_scope :creators,                scope_for_vocabulary_id(34)
  named_scope :contributors,            scope_for_vocabulary_id(34)
  named_scope :publishers,              scope_for_vocabulary_id(36)
  named_scope :languages,               scope_for_vocabulary_id(14, {:visible => true})
  named_scope :rfc_5646_languages,      scope_for_vocabulary_id(37, {:visible => true})
  named_scope :coverages,               scope_for_vocabulary_id(33)
  named_scope :digital_formats,         scope_for_vocabulary_id(9)
  named_scope :digital_types,           scope_for_vocabulary_id(10)
  named_scope :content_types,           scope_for_vocabulary_id(6)
  named_scope :general_subjects,        scope_for_vocabulary_id(31)
  named_scope :accrual_methods,         scope_for_vocabulary_id(45)
  named_scope :accrual_periodicities,   scope_for_vocabulary_id(46)
  named_scope :accrual_policies,        scope_for_vocabulary_id(44)
  named_scope :standards,               scope_for_vocabulary_id(30)
  named_scope :periods,                 scope_for_vocabulary_id(17)
  named_scope :spatial_coverages,       scope_for_vocabulary_id(29)
  named_scope :civilisations,           scope_for_vocabulary_id(5)
  named_scope :project_statuses,        scope_for_vocabulary_id(20)
  named_scope :digitisation_processes,  scope_for_vocabulary_id(11)
  named_scope :fundings,                scope_for_vocabulary_id(12)
  named_scope :digital_object_types,    scope_for_vocabulary_id(42)
  named_scope :mime_types,              scope_for_vocabulary_id(35)
  named_scope :iso_6391_languages,      scope_for_vocabulary_id(41)
  named_scope :iso_3166_countries,      scope_for_vocabulary_id(40)

end

