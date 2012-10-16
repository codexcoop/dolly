class EntityMetadataStandard < ActiveRecord::Base
#  default_scope :include => [:entity, :metadata_standard]

  belongs_to :entity
  belongs_to :metadata_standard
end

