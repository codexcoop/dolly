class Person < ActiveRecord::Base

  has_many :original_objects_as_creator,
    :class_name => 'OriginalObjectPerson',
    :foreign_key => :person_id,
    :source => :original_object,
    :conditions => {:dc_element => 'creator'}

  has_many :original_objects_as_contributor,
    :class_name => 'OriginalObjectPerson',
    :foreign_key => :person_id,
    :source => :original_object,
    :conditions => {:dc_element => 'contributor'}

end

