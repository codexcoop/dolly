class Element < ActiveRecord::Base
  include Restrictable
  include CustomCounterCachable

  belongs_to :metadata_standard
  belongs_to :entity
  belongs_to :vocabulary

  restrict_destroy_if_dependent :property_elements

  def name_with_section
    ("#{section} - " if section.present?).to_s + "#{name}"
  end

  has_many :property_elements
  has_many :properties, :through => :property_elements

  %W{name metadata_standard_id section entity_id cardinality requirement position datatype human_en description_en human_it description_it}.each do |model_attribute|
    validates_presence_of model_attribute.to_sym
  end

  def self.perform_force_counter_cache_reset
    self.force_counter_cache_reset  :property_elements_count => :property_elements
  end

end

