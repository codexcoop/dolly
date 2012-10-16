class Entity < ActiveRecord::Base

  has_many :entity_metadata_standards
  has_many :metadata_standards, :through => :entity_metadata_standards
  accepts_nested_attributes_for :entity_metadata_standards,
                                :allow_destroy => true,
                                :reject_if => lambda{|attrs| attrs['metadata_standard_id'].blank?}
#  validates_associated :entity_metadata_standards
#  validates_associated :metadata_standards

  has_many  :properties
  has_many  :vocabularies, :through => :properties, :conditions =>  "properties.vocabulary_id IS NOT NULL"

  accepts_nested_attributes_for :properties,
                                :allow_destroy => true,
                                :reject_if => lambda{|attributes| attributes['entity_id'].blank? or attributes['vocabulary_id'].blank?}

end

