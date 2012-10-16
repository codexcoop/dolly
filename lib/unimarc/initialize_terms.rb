# TODO: use namespaces
module UnimarcInitializeTerms

  def initialize_entity_terms(opts={})
    opts.assert_required_keys :unimarc_text, :property_name
    opts.assert_valid_keys :unimarc_text, :property_name, :unimarc_coordinates, :leader_positions
    prop = property_by_name(opts[:property_name])

    collected_terms = collect_terms_from_unimarc  :unimarc_text => opts[:unimarc_text],
                                                  :property_name => opts[:property_name],
                                                  :unimarc_coordinates => opts[:unimarc_coordinates],
                                                  :leader_positions => opts[:leader_positions]

    collected_terms.each do |collected_term|
      self.entity_terms.build(:property_id => prop.id, :vocabulary_id => prop.vocabulary_id).term = collected_term
    end
  end

  # TODO: shorten option names
  def collect_terms_from_unimarc(opts={})
    opts.assert_required_keys :unimarc_text, :property_name
    opts.assert_valid_keys :unimarc_text, :property_name, :unimarc_coordinates, :leader_positions
    unimarc_text        = opts[:unimarc_text]
    unimarc_hash        = unimarc_to_hash(unimarc_text)
    prop                = property_by_name(opts[:property_name])
    unimarc_coordinates = [opts[:unimarc_coordinates]].flatten
    leader_positions    = [opts[:leader_positions]].flatten
    terms               = []

    if leader_positions && leader_positions.any?
      leader_positions.each do |position|
        terms << find_or_initialize_term_from_leader(:position => position.to_i, :unimarc_text => unimarc_text, :vocabulary_id => prop.vocabulary_id )
      end
    end

    if unimarc_coordinates
      unimarc_coordinates.each do |unimarc|
        terms +=  find_or_initialize_terms_from_unimarc_field(
                    :field => unimarc[:field],
                    :unimarc_hash => unimarc_hash,
                    :vocabulary_id => prop.vocabulary_id,
                    :it => unimarc[:it],
                    :en => unimarc[:en],
                    :code => unimarc[:code]
                  )
      end
    end

    terms
  end

  # TODO: shorten method names
  def find_or_initialize_term_by_attributes(attrs={})
    attrs.assert_valid_keys :en, :it, :code, :vocabulary_id
    attrs.assert_required_keys :vocabulary_id
    conditions =  Term.merge_conditions(
                    {:vocabulary_id => attrs[:vocabulary_id]},
                    interpolate_conditions_in_or(:code => attrs[:code], :it => attrs[:it], :en => attrs[:en])
                  )
    existing_term = Term.find(:first, :conditions => conditions)
    existing_term || Term.new(:vocabulary_id => attrs[:vocabulary_id], :code => attrs[:code], :it => attrs[:it], :en => attrs[:en])
  end

  def find_or_initialize_term_from_leader(opts={})
    opts.assert_valid_keys :position, :unimarc_text, :vocabulary_id
    opts.assert_required_keys :position, :unimarc_text, :vocabulary_id

    leader    = get_leader_from_unimarc_text(opts[:unimarc_text])
    value_it  = decode_unimarc_leader :position => opts[:position], :language => :it, :leader => leader
    value_en  = decode_unimarc_leader :position => opts[:position], :language => :en, :leader => leader

    find_or_initialize_term_by_attributes :vocabulary_id => opts[:vocabulary_id], :it => value_it, :en => value_en
  end

  def find_or_initialize_terms_from_unimarc_field(opts={})
    opts.assert_required_keys :field, :unimarc_hash, :vocabulary_id
    opts.assert_valid_keys    :field, :unimarc_hash, :vocabulary_id, :it, :en, :code
    field         = opts[:field]
    unimarc_hash  = opts[:unimarc_hash]
    vocabulary_id = opts[:vocabulary_id]
    it            = opts[:it]
    en            = opts[:en]
    code          = opts[:code]

    terms = []
    if unimarc_hash[field].present?
      unimarc_hash[field].each do |field_occurrence|
        it_value = scan_unimarc_field_occurrence(field_occurrence, '/', it)
        en_value = scan_unimarc_field_occurrence(field_occurrence, '/', en)
        code_value = scan_unimarc_field_occurrence(field_occurrence, '/', code)
        if [it_value, en_value, code_value].any?(&:present?)
          terms << find_or_initialize_term_by_attributes( :vocabulary_id => vocabulary_id,
                                                          :it   =>  it_value.present? ? it_value : nil,
                                                          :en   =>  en_value.present? ? en_value : nil,
                                                          :code =>  code_value.present? ? code_value : nil )
        end
      end
    end

    terms
  end

  # builds the conditions in the form [string, hash],
  # according to best practices of SQL injection prevention
  # example:
  #   > conditions = {:en=>"english", :code=>3, :it=>"italiano"}
  #   > OriginalObject.new.build_conditions_in_or(conditions)
  #   => ["en = :en OR it = :it OR code = :code", {:en=>"english", :it=>"italiano", :code=>3}]
  def interpolate_conditions_in_or(conditions_hash)
    conditions_hash.assert_valid_keys :en, :it, :code
    [conditions_string_in_or(conditions_hash), conditions_hash]
  end

  # builds a correctly interpolated string with attributes linked by 'OR'
  def conditions_string_in_or(conditions_hash)
    clean_conditions_hash(conditions_hash).keys.inject([]) {|snippets, k| snippets << "#{k.to_s} = :#{k.to_s}"}.join(" OR ")
  end

  def clean_conditions_hash(conditions_hash, opts={})
    opts.assert_valid_keys :rejected_keys
    invalid_keys = [opts[:rejected_keys]].flatten || []
    conditions_hash.delete_if{|k,v| invalid_keys.include?(k) || v.blank?}
  end

#  def find_or_initialize_person(attrs={})
#    [:identifier, :source, :name, :rule]
#    person_by_identifier  = Person.find(:first, :conditions => {:identifier => attrs[:identifier], :source => attrs[:source]})
#    person_by_name        = Person.find(:first, :conditions => {:name => attrs[:name], :rule => attrs[:rule]})

#    person_by_identifier ||
#    person_by_name ||
#    Person.new(
#      :identifier => attrs[:identifier],
#      :source => attrs[:source],
#      :name => attrs[:name],
#      :rule => attrs[:rule]
#    )
#  end

#  def initialize_original_object_person(attrs={})
#    association_suffix  = attrs[:dc_element].to_s.tableize # => :creator => "Creator"
#    dc_element          = association_suffix.classify # => :creator => "Creator"
#    person              = find_or_initialize_person(attrs)

#    association         = self.send(:"original_object_#{association_suffix}").
#                               build(:dc_element => dc_element, :unimarc_relator_code => attrs[:unimarc_relator_code])
#    association.person  = person
#  end

#  def collect_people_from_unimarc(opts={})
#    opts.assert_required_keys :unimarc_hash
#    opts[:unimarc_hash]['702'].each do |field_occurrence|
##      field_occurrence.
#    end
#  end

end

