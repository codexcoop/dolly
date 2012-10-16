module AutoconfigureEntity
  def self.included(klass)
    klass.extend ClassMethods
    klass.initialize_included_entity_features
  end

  def compact_entity_terms
    self.entity_terms.uniq_by! do |entity_term|
      [entity_term.term.translation_coalesce, entity_term.property_id]
    end
  end

  def entity_term_destruction_conditions?(entity_term)
    entity_term.marked_for_destruction?
  end

  def destroy_marked_entity_terms
    self.entity_terms.each {|et| et.destroy if et.marked_for_destruction? }.
                      delete_if {|et| entity_term_destruction_conditions?(et) }
  end

  def vocabulary_ids_from_params
    self.entity_terms.map(&:vocabulary_id).uniq.compact
  end

  def property_ids_from_params
    self.entity_terms.map(&:property_id).uniq.compact
  end

  def properties
    Entity.find_by_name(self.class.name).properties
  end

  def to_metadata_standard(metadata_standard_name)
    metadata_standard_id = MetadataStandard.
       find(:first,
            :conditions => ["name = :metadata_standard_name OR description = :metadata_standard_name",
                            {:metadata_standard_name => metadata_standard_name}],
            :select => "id").
       try(:id)
    metadata_array = []

    if metadata_standard_id
      initialize_virtual_attributes if respond_to? :initialize_virtual_attributes
      Entity.find_by_name(self.class.name).properties.each do |property|
        element = property.elements.find :first,
                                         :conditions => {:metadata_standard_id => metadata_standard_id}

        if element and element.requirement != 'automatic'
          properties_method = if property.cardinality == 'one' then property.name else property.name.tableize end
          value = self.send(properties_method.to_sym)
          if value and value.is_a?(Array)
            if value.any? and value.first.respond_to?(:translation_coalesce)
              metadata_array << [element.position, element.name, value.map(&:translation_coalesce)]
            else
              metadata_array << [element.position, element.name, [nil] ]
            end
          elsif value.respond_to?(:translation_coalesce)
            metadata_array << [element.position, element.name, value.translation_coalesce]
          else
            metadata_array << [element.position, element.name, value]
          end
        end
      end
    end

    metadata_array.sort_by{|element| element[0]}.map{|element| element[1..2]}
  end

  module ClassMethods
    # relations v.2011 support
    #DigitalCollection.properties_with_vocabularies.map do |prop|
    #  {
    #    :name => ( prop.cardinality == 'many' ? prop.name.tableize.to_sym : prop.name.to_sym ) ,
    #    :cardinality => prop.cardinality,
    #    :requirement => prop.requirement,
    #    :conditions => {
    #      :vocabulary_id => prop.vocabulary_id,
    #      :property_id => prop.id
    #    }
    #  }
    #end
    def define_associations_for_properties(given_properties)
      given_properties.each do |p|
        # through_association both for has_many and has_one through
        through_association_name  = "#{self.name.underscore}_#{p[:name].to_s.tableize}".to_sym
        association_name          = p[:name].to_sym
        has_many  through_association_name, :class_name => "#{self.name}Term",
                  :conditions => p[:conditions],
                  :dependent => :destroy
        accepts_nested_attributes_for through_association_name,
                                      :allow_destroy => true,
                                      :reject_if => lambda{|params| params['term_id'].blank? }
        alias_method :"sorted_#{through_association_name}", :"#{through_association_name}"
        # has_many or has_one association specific to property
        if p[:cardinality] == 'many'
          has_many  association_name, :class_name => 'Term',
                    :through => through_association_name, :source => :term
        else
          has_one   association_name, :class_name => 'Term',
                    :through => through_association_name, :source => :term
        end
        # validation for mandatory properties
        if p[:requirement] == 'mandatory'
          error_method = "#{p[:name].to_s.tableize.singularize}_error".to_sym
          attr_accessor error_method
          validation_method = "at_least_one_#{p[:name].to_s.tableize.singularize}".to_sym
          validate validation_method
          define_method(validation_method) do
             if send(through_association_name).select{|r| !r.marked_for_destruction? }.size < 1
              errors.add_to_base(:at_least_one)
              send("#{error_method}=".to_sym, true)
            end
          end
        end
      end
    end

    # TODO: use a generic name
    def initialize_included_entity_features
      before_validation :compact_entity_terms
      before_validation :destroy_marked_entity_terms

      has_many :entity_terms, :class_name => "#{self.name}Term", :autosave => true
      has_many :terms, :through => :entity_terms
      belongs_to :user
      validates_presence_of :user_id

      accepts_nested_attributes_for :entity_terms,
                  :allow_destroy => true,
                  :reject_if => Proc.new {|attrs|
                    ( attrs['term_attributes'].present? &&
                        attrs['term_attributes']['it'].present? &&
                        Term.find(:first,
                                  :conditions => {:it => attrs['term_attributes']['it'],
                                                  :vocabulary_id => attrs['term_attributes']['vocabulary_id'] }) ) ||
                    ( attrs['term_id'].blank? &&
                        ( attrs['term_attributes'].blank? ||
                          attrs['term_attributes']['it'].blank?) ) }

      # TODO: put this cycle in a method, so that it could have a name
      # FIXME: make correct sql interpolation
      self.properties_with_vocabularies_has_many.each do |property|
        has_many  property.name.tableize.to_sym,
                  :class_name => 'Term',
                  :through => :entity_terms,
                  :source => :term,
                  :conditions => "#{self.name.tableize.singularize}_terms.property_id = '#{property.id}'"

        attr_reader :"#{property.name}_error"

        define_validation_for_property_with_vocabularies(property)

        #validate :"at_least_one_#{property.name}"
      end

      # TODO: put this cycle in a method, so that it could have a name
      # FIXME: make correct sql interpolation
      self.properties_with_vocabularies_has_one.
          delete_if{|p| p.requirement.included_in?(['automatic_internal', 'automatic_third_party'])}.
          each do |property|
        has_one property.name.to_sym,
                :through => :entity_terms,
                :class_name => 'Term',
                :source => :term,
                :counter_cache => :entities_count,
                :conditions => "#{self.name.tableize.singularize}_terms.property_id = '#{property.id}'"

        attr_reader :"#{property.name}_error"

        define_validation_for_property_with_vocabularies(property)

        #validate :"at_least_one_#{property.name}"
      end
    end # initialize_included_entity_features

    # load the files of the model, so that objects of the correct specific class
    # will be created when loading the YAML
    load 'property.rb'
    load 'vocabulary.rb'

    def properties_with_vocabularies
      @properties_with_vocabularies ||=
          Entity.find_by_name(self.name).
                 properties.find(:all, :include => :vocabulary, :joins => :vocabulary, :select => "properties.*, vocabularies.is_user_editable AS vocabulary_is_user_editable", :order => 'position').
                 select{|p| (p.vocabulary_id.present?)}
                 #. && p.requirement != 'automatic_internal' && p.requirement != 'automatic_third_party'
                 # sort_by{|p| p.position}
                 # sort_by{|p| [p.section.to_s, p.position]}
    end

    # TODO: all the following methods could be DRY and in a separate module
    # OPTIMIZE: .downcase should not be required anymore
    def yaml_path_for(associated_objects)
      File.join(RAILS_ROOT,
                'app',
                'models',
                "#{self.name.tableize.singularize.downcase}_#{associated_objects.to_s}.yml")
    end

    def properties_with_vocabularies_yaml_file_name
      yaml_path_for :properties_with_vocabularies
    end

    # OPTIMIZE: File::new should be used with a block
    def write_properties_with_vocabularies_to_yaml
      # OPTIMIZE: use a block for working wih files
      yml_file = File.new(properties_with_vocabularies_yaml_file_name, 'w+')
      yml_file.write(self.properties_with_vocabularies.to_yaml)
      yml_file.close
    end

    # OPTIMIZE: if the file does not exists should be created instead of returning an empty array
    def read_properties_with_vocabularies_from_yaml
      if File.exist? properties_with_vocabularies_yaml_file_name
        YAML.load_file(properties_with_vocabularies_yaml_file_name)
      else
        []
      end
    end

    # OPTIMIZE: use "alias_method" instead
    def properties_with_vocabularies_all
      read_properties_with_vocabularies_from_yaml
    end

    # OPTIMIZE: DRY
    def properties_with_vocabularies_for_views_all
      self.properties_with_vocabularies_all.
           delete_if{|p| p.requirement.included_in?(['automatic_internal', 'automatic_third_party'])}
    end

    def properties_with_vocabularies_has_many
      self.properties_with_vocabularies_all.select{|property| property.cardinality=='many'}
    end

    def properties_with_vocabularies_has_one
      self.properties_with_vocabularies_all.select{|property| property.cardinality=='one'}
    end

    def properties_with_vocabularies_for_views_has_many
      self.properties_with_vocabularies_for_views_all.select{|property| property.cardinality=='many'}
    end

    def properties_with_vocabularies_for_views_has_one
      self.properties_with_vocabularies_for_views_all.select{|property| property.cardinality=='one'}
    end

    # TODO: convert to static method
    def define_validation_for_property_with_vocabularies(property)
      define_method :"at_least_one_#{property.name}" do
        unless  property_ids_from_params.include?(property.id) || property.requirement != 'mandatory'
          errors.add_to_base "At least one term is required for the property #{property.name}"
          instance_variable_set(:"@#{property.name}_error", true)
        end
      end
    end

  end
end

