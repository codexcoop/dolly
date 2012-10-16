class UnimarcLink < ActiveRecord::Base

  include UnimarcConfig
  include Descriptor

  define_description_for_attribute :qualifier do |qualifier, language|
    language ||= :it
    UnimarcConfig::UNIMARC_LINK_FIELDS[qualifier.to_s][:description][language.to_sym]
  end

  belongs_to :original_object
  validates_presence_of :bid, :original_object_id, :qualifier

  belongs_to :linked_original_object, :class_name => 'OriginalObject', :foreign_key => :bid, :primary_key => :bid

  def missing_linked?
    linked_original_object.nil?
  end

  def title_and_bid
    if title
      "#{title} [#{bid}]"
    else
      bid
    end
  end

end

