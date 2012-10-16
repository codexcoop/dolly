module DigitalCollectionsHelper

  def digital_objects_link_text_for_digital_collection(digital_collection)
    t(:digital_object,  :count =>  digital_collection.digital_objects.size, :scope => [:activerecord, :models]).downcase
  end

  def link_to_digital_objects_for_digital_collection(digital_collection)
    if digital_collection.digital_objects.size > 0
      link_to digital_objects_link_text_for_digital_collection(digital_collection), digital_collection_digital_objects_path(digital_collection)
    end
  end

end

