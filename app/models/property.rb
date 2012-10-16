class Property < ActiveRecord::Base

  @requirements         = %w(mandatory optional recommended automatic_internal automatic_third_party)
  @cardinalities        = %w(one many) # one_with_link
  @form_field_types     = %w(text_field text_area check_box select radio_button file_browser)
  @data_types           = %w(string text integer boolean decimal date reference attachment)
  @order_terms_by       = %w(code it en translation_coalesce position)
  @unimarc_method_types = [1, 2, 3, 4, 5]

  class << self
    attr_reader :requirements, :cardinalities, :form_field_types, :data_types, :unimarc_method_types, :order_terms_by
  end

  after_save Proc.new {
    self.generate_yaml_help('en')
    self.generate_yaml_help('it')
    [OriginalObject, Project, DigitalCollection, DigitalObject].each(&:write_properties_with_vocabularies_to_yaml)
  }

  %W{name position cardinality requirement datatype form_field_type}.each do |model_attribute|
    validates_presence_of model_attribute.to_sym
  end

  # TODO: restore inclusion validations when the entity_vocabularies is stable
  #  validates_inclusion_of :requirement, :in => ['mandatory', 'optional', 'recommended', nil]
  #  validates_inclusion_of :cardinality, :in => ['one', 'many', 'one_with_link', nil]

  belongs_to :entity
  validates_presence_of :entity_id

  belongs_to :vocabulary

  belongs_to :visibility, :class_name => 'Role'
  validates_presence_of :visibility_id

  validates_presence_of :position
  validates_numericality_of :position

  has_many :property_elements, :dependent => :destroy
  has_many :elements, :through => :property_elements
  accepts_nested_attributes_for :property_elements, :allow_destroy => true,
                                :reject_if => lambda{|attributes| attributes['element_id'].blank? }

  def attribute_for_help
    if self.cardinality == 'one' and self.vocabulary
      self.name
    elsif self.cardinality == 'many'
      self.name.classify.tableize
    else
      self.name
    end
  end

  def self.generate_yaml_help(language=nil)
    language ||= 'en'

    # [['digital_collection', {'dc_format' => "this field is meant to.. etc..."}], ...]
    flat_collect = self.all.collect do |property|
                              [ property.entity.name.tableize.singularize,
                                {property.attribute_for_help => property.send(:"description_#{language}")} ]
                            end

    grouped_hash = {}

    flat_collect.group_by{|record| record[0]}.each_pair do |entity, records|
      grouped_hash[entity] =  records.
                              collect{|record| record[1]}.
                              inject(content_hash={}){|content_hash, record| content_hash.merge(record) }
    end

    # grouped_hash is now... {'digital_collection' =>
    #                           { 'dc_format' => 'description of dc_format...',
    #                             'michael_address' => 'description of michael_address',...}
    #                           }
    help_filename = "#{RAILS_ROOT}/config/locales/help/#{language}.yml"
    success = true
    begin
      yaml_file = File.new(help_filename, 'w')
      yaml_file.write({language => {'help' => grouped_hash}}.to_yaml)
      puts help_filename + " successfully created."
    rescue
      success = false
      puts "Problems during the creation of file. Please retry."
    ensure
      yaml_file.close
    end
    success
  end

end

