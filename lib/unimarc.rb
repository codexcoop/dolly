# TODO: [important]: document, at least with a summary, UNIMARC import
require 'pp'
require 'unimarc/config'
require 'unimarc/links'
require 'unimarc/parsing'
require 'unimarc/mapping'
require 'unimarc/initialize_terms'

module Unimarc

  include UnimarcConfig
  include UnimarcLinks
  include UnimarcParsing
  include UnimarcMapping
  include UnimarcInitializeTerms

  def initialize_with_unimarc(unimarc_text)
    load_properties_from_db.each do |prop|
      property_method = prop.cardinality == 'many' ? prop.name.tableize : prop.name
      import_method = "import_#{property_method}_from_unimarc"
      send(import_method.to_sym, unimarc_text) if respond_to?(import_method.to_sym)
    end

    terms_associations = self.class.reflect_on_all_associations.select { |ass| ass.class_name == "#{self.class.name}Term" }
    # => [:original_object_creators, :original_object_publishers,
    #     :original_object_coverages, :entity_terms, :original_object_subjects,
    #     :original_object_contributors, :original_object_languages,
    #     :original_object_object_types]
    terms_associations.each do |terms_association|
      next unless terms_association.options[:conditions]
      self.entity_terms.each do |entity_term|
        term = entity_term.term
        term.save && entity_term.term_id = term.id if term.new_record?

        conditions =  entity_term.vocabulary_id == terms_association.options[:conditions][:vocabulary_id] &&
                      entity_term.property_id == terms_association.options[:conditions][:property_id]
        self.send(terms_association.name) << entity_term if conditions
      end
    end

    self
  end

end

