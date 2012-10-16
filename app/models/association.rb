class Association < ActiveRecord::Base

  include Unimarc
  include UnimarcConfig
  include Descriptor

  after_save :update_main_association_in_original_object
  before_destroy :reset_main_association_in_original_object

  def update_main_association_in_original_object(main_qualifier='461')
    return unless self.qualifier == main_qualifier
    original_object.update_attributes(
      :main_association_qualifier => qualifier,
      :main_related_title => related_original_object.title,
      :main_related_id => related_original_object.id
    )
  end

  def reset_main_association_in_original_object
    original_object.update_attributes(
      :main_association_qualifier => nil,
      :main_related_title => nil,
      :main_related_id => nil
    )
  end

  belongs_to :original_object

  belongs_to :related_original_object,
    :class_name => 'OriginalObject',
    :foreign_key => :related_original_object_id

  define_description_for_attribute :qualifier do |qualifier, language|
    language ||= :it
    UnimarcConfig::UNIMARC_LINK_FIELDS[qualifier.to_s][:description][language.to_sym]
  end

end

