require 'pp'

# TODO: use namespaces
module UnimarcMapping

  # TODO: uniform the use of unimarc_hash and unimarc_simple_hash
  # TODO: prevent 'n' parsings of unimarc_text to hash

  def view_publication_string_from_unimarc(unimarc_text)
    unimarc_simple_hash = unimarc_to_simple_hash(unimarc_text)
    if unimarc_simple_hash['210'].present?
      tmp_publication_string = unimarc_simple_hash['210'].first
      tmp_publication_string << ')' if tmp_publication_string =~ /\$e/
      tmp_publication_string.sub(/\s*\$a/,"").
                             gsub(/\s*\$a/, "; ").
                             gsub(/\$b/,'').
                             gsub(/\$c/, " : ").
                             gsub(/\s*\$d/, ", ").
                              sub(/\$e\s*/, "(").
                             gsub(/\$e/, "").
                             gsub(/\$f/, " ; ").
                             gsub(/\$g/, " : ").
                             gsub(/\s*\$h/, ", ").
                             strip.
                             squeeze("\s+").
                             gsub(/^\s*:\s*|^\s*;\s*|^\s*,\s*|/,'')
    end
  end

  # TODO: all the "import_" methods should be converted to DSL and put in a config module

  def import_title_from_unimarc(unimarc_text)
    unimarc_simple_hash = unimarc_to_simple_hash(unimarc_text)
    if unimarc_simple_hash['200'].present?
      self.title = title_with_punctuation(unimarc_simple_hash['200'].first)
    end
  end

  def title_with_punctuation(title_unimarc_string)
    title_unimarc_string.sub(/\s*\$a/,"").
      gsub(/\s*\$a/, "; ").
      gsub(/\$b.*?(?=\$)|\$b.*$/){|match| "\[#{match}\]"}.gsub(/\s+\]/, "]").
      gsub(/\s*\$c/, ". ").
      gsub(/\s*\$d/, " = ").
      gsub(/\s*\$e/, ": ").
      gsub(/\s*\$f/, " / ").
      gsub(/\s*\$g/, "; ").
      gsub(/\s*\$h/, ". ").
      gsub(/\s*\$i(?!.*\$h)/, ". ").
      gsub(/\s*\$i/, ", ").
      strip.
      squeeze("\s+")
  end

  def import_description_from_unimarc(unimarc_text)
    unimarc_hash = unimarc_to_hash(unimarc_text)
    unimarc_simple_hash = unimarc_to_simple_hash(unimarc_text)
    content = []

    %w{300 330}.each do |unimarc_field_code|
      if unimarc_hash[unimarc_field_code].present?
        content << unimarc_hash[unimarc_field_code].map{|field_occurrence| field_occurrence['$a']}.
                                                    join("\n").
                                                    strip.squeeze("\s+")
      end
    end

    self.description = content.join("\n").gsub(/^\n+|\n+$/, '').squeeze("\n")
  end

  def import_physical_description_from_unimarc(unimarc_text)
    unimarc_hash = unimarc_to_hash(unimarc_text)
    unimarc_simple_hash = unimarc_to_simple_hash(unimarc_text)
    content = []

    if unimarc_simple_hash['215'].present?
      unimarc_simple_hash['215'].each do |field_occurrence|
        content << field_occurrence.gsub(/\s*\$a/, "\n").
                                    gsub(/\s*\$c/, " : ").
                                    gsub(/\s*\$d/, " ; ").
                                    gsub(/\s*\$e/, " + ").
                                    strip.squeeze("\s+")
      end
    end

    self.physical_description = content.join("\n").gsub(/^\n+|\n+$/, '').squeeze("\n")
  end

  def import_bid_from_unimarc(unimarc_text)
    unimarc_simple_hash = unimarc_to_simple_hash(unimarc_text)
    self.bid = unimarc_simple_hash['001'].first.strip.squeeze("\s+") if unimarc_simple_hash['001'] && unimarc_simple_hash['001'].any?
  end

  def import_tmp_unimarc_links_from_unimarc(unimarc_text)
    unimarc_hash = unimarc_to_hash(unimarc_text)
    unimarc_links_array = unimarc_hash.select{|k,v| Unimarc::UNIMARC_LINK_FIELDS.include?(k)}
    self.tmp_unimarc_links = Hash[*unimarc_links_array.flatten(1)] if unimarc_links_array.present?
  end

  def import_isbn_from_unimarc(unimarc_text)
    # OPTIMIZE: nei casi di ISBN multipli, catturarne uno solo
    # Esempio: IT\ICCU\VIA\0095449
    unimarc_hash = unimarc_to_hash(unimarc_text)
    if unimarc_hash['010'].present?
      self.isbn = unimarc_hash['010'].map{|field_occurrence| field_occurrence['$a']}.join(' / ').strip.squeeze("\s+")
    end
  end

  def import_issn_from_unimarc(unimarc_text)
    unimarc_hash = unimarc_to_hash(unimarc_text)
    if unimarc_hash['011'].present?
      self.issn = unimarc_hash['011'].map{|field_occurrence| field_occurrence['$a']}.join(' / ').strip.squeeze("\s+")
    end
  end

  def import_source_from_unimarc(unimarc_text)
    unimarc_simple_hash = unimarc_to_simple_hash(unimarc_text)
    if  unimarc_simple_hash['324'] &&
        unimarc_simple_hash['324'].any? &&
        unimarc_simple_hash['324'].first['$a']
    then
      self.source = unimarc_simple_hash['324'].first['$a'].first
    end
  end

  def import_string_date_from_unimarc(unimarc_text)
    unimarc_hash = unimarc_to_hash(unimarc_text)
    content = []
    if unimarc_hash['210'].present?
      unimarc_hash['210'].each do |field_occurrence|
        content << field_occurrence['$d'].join(' , ') + ' , ' if field_occurrence['$d'] && field_occurrence['$d'].any?
        content << field_occurrence['$h'].join(' , ') + ' , ' if field_occurrence['$h'] && field_occurrence['$h'].any?
      end
    end

    self.string_date = content.join.gsub(/^\s*,+\s*|\s*,+\s*$/, '').squeeze("\s+")
  end

  def import_types_from_unimarc(unimarc_text)
    initialize_entity_terms :property_name => 'type',
                            :unimarc_text => unimarc_text,
                            :unimarc_coordinates => [ {:field => '135', :it => '$a', :en => '$a'},
                                                      {:field => '230', :it => '$a', :en => '$a'} ],
                            :leader_positions => 6
  end

  def import_subjects_from_unimarc(unimarc_text)
    initialize_entity_terms :property_name => 'subject',
                            :unimarc_text => unimarc_text,
                            :unimarc_coordinates => [ {:field => '610', :it => '$a', :en => '$a'},
                                                      {:field => '606', :it => '$a', :en => '$a', :code => '$3'},
                                                      {:field => '676', :it => '$av1', :code => '$av'} ]
  end

  def import_creators_from_unimarc(unimarc_text)
    initialize_entity_terms :property_name => 'creator',
                            :unimarc_text => unimarc_text,
                            :unimarc_coordinates => [ {:field => '700', :it => '$ab', :en => '$ab', :code => '$3'},
                                                      {:field => '710', :it => '$ab', :en => '$ab', :code => '$3'} ]
  end

  def import_contributors_from_unimarc(unimarc_text)
    initialize_entity_terms :property_name => 'contributor',
                            :unimarc_text => unimarc_text,
                            :unimarc_coordinates => [ {:field => '701', :it => '$ab', :en => '$ab', :code => '$3'},
                                                      {:field => '702', :it => '$ab', :en => '$ab', :code => '$3'},
                                                      {:field => '712', :it => '$ab', :en => '$ab', :code => '$3'} ]
  end

  def import_publishers_from_unimarc(unimarc_text)
    initialize_entity_terms :property_name => 'publisher',
                            :unimarc_text => unimarc_text,
                            :unimarc_coordinates => [ {:field => '210', :it => '$c', :en => '$c'},
                                                      {:field => '210', :it => '$g', :en => '$g'} ]
  end

  def import_languages_from_unimarc(unimarc_text)
    prop = property_by_name('language')
    unimarc_hash = unimarc_to_hash(unimarc_text)
    if unimarc_hash['101'] && unimarc_hash['101'].first && unimarc_hash['101'].first['$a']
      unimarc_hash['101'].first['$a'].each do |language_code|
        term = find_or_initialize_term_by_attributes :vocabulary_id => prop.vocabulary_id, :code => language_code
        self.entity_terms.build(:property_id => prop.id, :vocabulary_id => prop.vocabulary_id).term = term
      end
    end
  end

  def import_coverages_from_unimarc(unimarc_text)
    initialize_entity_terms :property_name => 'coverage',
                            :unimarc_text => unimarc_text,
                            :unimarc_coordinates => [ {:field => '210', :it => '$a', :en => '$a'} ]
  end

end

