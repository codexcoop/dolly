class MetadataStandard < ActiveRecord::Base
  # es: Mets, Michael, Mods...

  include Restrictable

  before_destroy 'restrict_if_dependent(:elements)' # use single quotes (not double quotes), so it becomes
                                                        # an inline eval method, and will be evaluated only
                                                        # when the callback is triggered


  has_many :entity_metadata_standards

  has_many :elements
  has_many :vocabularies, :through => :elements, :conditions => "elements.vocabulary_id IS NOT NULL"

end

