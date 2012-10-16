module OriginalObjectsHelper

  def original_object_row_title(original_object)
    content = link_to h(original_object.title), original_object_path(original_object)
    content << ", #{original_object.string_date}" if original_object.string_date.present?
    content
  end

  def original_object_row_association(original_object)
    # FIXME: [IMPORTANT] sanare forte incoerenza tra voce di lista original_objects e digital_objects.
    # Qui "Fa parte di" in riga a sé, mentre in original_objects su unica riga del titolo
    
    # TODO: completare con la semantica corretta delle associazioni (ved. 462, 463)
    # Aggiungere anche l'include di :related in OriginalObjectsController =>  def find_original_objects
    # select{|orig_obj| orig_obj.qualifier == '461'}

    if original_object.main_association_qualifier.present?
      content_tag(:p,
                  content_tag(:em, original_object.main_association_qualifier.description(I18n.locale)) +
                  ": " + original_object.main_related_title,
                  :class => "item-title")
    end
  end

  def digital_objects_link_text_for(original_object)
    t(:digital_object,  :count =>  original_object.digital_objects.size, :scope => [:activerecord, :models]).downcase
  end

  # OPTIMIZE: quando ci saranno almeno 2 oggetti digitali (as es. PDF), verificare funzionalità di passaggio da pagina intermedia
  def link_to_digital_objects_for(original_object)
    if original_object.digital_objects.size == 1
      link_to digital_objects_link_text_for(original_object), digital_object_path(original_object.digital_object_ids)
    elsif original_object.digital_objects.size > 1
      link_to digital_objects_link_text_for(original_object), original_object_digital_objects_path(original_object)
    end
  end

  # OPTIMIZE: instantiate less objects in unimarc parsing
  def z3950_embedded_label(unimarc_field, embedded_records)
    "".tap do |content|
      content << tag(:br) + "<em>" + Unimarc.description_for_unimarc_link(unimarc_field, I18n.locale) + "</em>: "
      embedded_records.each do |embedded_record|
        content << embedded_record['200'] + "\n" if embedded_record['200'].present?
        content << " [" + embedded_record['001'] + "]" + "\n" if embedded_record['001'].present?
      end
    end
  end

  # TODO: [IMPORTANT] split this method
  def z3950_result_label(unimarc_text)
    content = ""

    orig_obj = OriginalObject.new

    unimarc_hash = orig_obj.unimarc_to_hash(unimarc_text)
    unimarc_simple_hash = orig_obj.unimarc_to_simple_hash(unimarc_text)

    if unimarc_hash['700'] && unimarc_hash['700'].any? && unimarc_hash['700'].first['$a'].present?
      content << h(unimarc_hash['700'].first['$a'].first.gsub(/\s*,/, ", ").strip.squeeze("\s")) + tag(:br) + "\n"
    end

    if unimarc_simple_hash['200'].present? && unimarc_simple_hash['200'].any?
      content << content_tag(:strong, h(orig_obj.import_title_from_unimarc(unimarc_text))) + tag(:br) + "\n"
    end

    if unimarc_hash['210'].present? && unimarc_hash['210'].any?
      publication = h(orig_obj.view_publication_string_from_unimarc(unimarc_text))
      content << publication + tag(:br) + "\n" if publication.size > 0
    end

    leader = orig_obj.get_leader_from_unimarc_text(unimarc_text)
    level = orig_obj.decode_unimarc_leader :position => 7, :language => :it, :leader => leader
    type = orig_obj.decode_unimarc_leader :position => 6, :language => :it, :leader => leader

    if unimarc_hash['001']
      content << h("#{level.capitalize} - #{type.capitalize} [#{unimarc_hash['001'].first.strip}]") + "\n"
    else
      content << h("#{level.capitalize} - #{type.capitalize}") + "\n"
    end

    # OPTIMIZE: confronta con risultato sintetico OPAC ad esempio: IT\ICCU\VIA\0095450
    Hash[*unimarc_hash.select{|field, values|['461'].include?(field)}.flatten(1)].each_pair do |field, embedded_records|
      content << z3950_embedded_label(field, embedded_records)
    end

    content
  end

end

