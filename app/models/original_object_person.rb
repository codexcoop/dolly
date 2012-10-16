class OriginalObjectPerson < ActiveRecord::Base

  belongs_to :person
  belongs_to :original_object

end

