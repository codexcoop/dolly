module DigitalObjectsHelper

  def toc_index_link(node)
    link_to node.description, toc_index_digital_object_path(instance_variable_get(:@digital_object), :node_id => node.id)
  end

  def check_toc_links(digital_object)
    conditions = []
    conditions << digital_object.no_processing_in_progress # FIXME: deprecated method
    conditions << digital_object.content_type.to_s =~ /^image/
    conditions << is_owner?(:authorizable_action => 'toc_index', :authorizable_object => digital_object)
    conditions.all?
  end

  def digital_object_download_link(digital_object)
    # NB: Non funziona. Ora digital_object.content_type è sempre nil.
    if digital_object.content_type == 'application/pdf'
      link_to t( "activerecord.attributes.digital_object.original_content_type.pdf", :count => 1 ),
              download_digital_object_path(digital_object)
    else
      ""
    end
  end

  def digital_object_digital_files_link(digital_object)
    # if digital_object.content_type =~ /^image/
    count = digital_object.digital_files_count
    if count > 0
      link_to t( "activerecord.attributes.digital_object.original_content_type.images", :count => count ),
              digital_object_digital_files_path(digital_object)
    else
      "Nessun file disponibile"
    end
  end

  def manage_files_or_download_link(digital_object)
    [
      digital_object_download_link(digital_object),
      digital_object_digital_files_link(digital_object)
    ].
    reject(&:blank?).first.to_s
  end

  def digital_object_toc_editor_link(digital_object)
    if check_toc_links(digital_object)
      link_to(t('.go_to_toc_editor'), toc_index_digital_object_path(digital_object))
    else
      ""
    end
  end

  def digital_object_mets_link(digital_object)
    if check_toc_links(digital_object)
      link_to("METS", (digital_object_path(digital_object) + ".xml"))
    else
      ""
    end
  end

  # TODO: I18n
  def digital_object_bookreader_link(digital_object)
    if digital_object.digital_files_count > 0 # bookreadable?
      link_to t(".bookreader"), bookreader_digital_object_path(digital_object)
    else
      ""
    end
  end

  def digital_object_list_links(digital_object)
    [].tap{|links|
      links << manage_files_or_download_link(digital_object)
      links << digital_object_toc_editor_link(digital_object)
      links << digital_object_bookreader_link(digital_object)
      links << digital_object_mets_link(digital_object) if digital_object.digital_files_count > 0
    }.
    reject(&:blank?).
    join(" | ")
  end

  def file_nav_link(display_text, direction)
    digital_object = instance_variable_get(:"@digital_object")
    file = instance_variable_get(:"@#{direction.to_s}_digital_file")
    if file
      link_to display_text, self.send(:digital_object_digital_file_path, digital_object, file)
    else
      display_text
    end
  end

  def digital_object_row_title(digital_object)
    "".tap do |content|
      if digital_object.original_object_main_related_title?
        content << "#{h digital_object.original_object_main_related_title} - "
      end
      content << link_to(h(digital_object.original_object_title), digital_object_path(digital_object))
      content << ", #{digital_object.original_object_string_date}" if  digital_object.original_object_string_date.present?
    end
  end

  def digital_object_row_collection(digital_object)
    unless params[:digital_collection_id]
      content_tag(:p, digital_object.digital_collection_title)
    end
  end

  def original_object_select_for_digital_object(form_builder, css_class, selected_original_object=nil)
    selected_original_object ||= form_builder.object.original_object
    choices_for_top_level = option_groups_from_collection_for_select(@top_level_original_objects, :main_dependents, :shortened_title, :id, :shortened_title, selected_original_object.try(:id))
    choices_for_stand_alone = options_from_collection_for_select(@stand_alone_original_objects, :id, :shortened_title, selected_original_object.try(:id))
    choices = choices_for_top_level + choices_for_stand_alone

    # f.select(:original_object_id, choices, options={:include_blank => '- seleziona -'}, html_options={})
    form_builder.select(
      :original_object_id,
      choices,
      {:include_blank => t("application.please_select")},
      {:class => css_class}
    )
  end

  def digital_collections_array_for_digital_object(digital_collections)
    digital_collections.map {|digital_collection|
      [digital_collection.title_with_project, digital_collection.id]
    }
  end

  def digital_collections_list_for_digital_object(digital_collections, selected_digital_collection=nil)
    options_for_select( digital_collections_array_for_digital_object(digital_collections),
                        selected_digital_collection.try(:id) )
  end

  def digital_collection_select_for_digital_object(form_builder, digital_collections, css_class, selected_digital_collection=nil)
    selected_digital_collection ||= form_builder.object.digital_collection
    form_builder.select(
      :digital_collection_id,
      digital_collections_list_for_digital_object(digital_collections, selected_digital_collection),
      {:include_blank => t("application.please_select")},
      {:class => css_class}
    )
  end

  # TODO: i18n
  def statuses
    ["In lavorazione", "Completo"]
  end

  def statuses_array
    statuses.zip([false, true])
  end

  def inverse_status(status)
    status == true ? statuses[0] : statuses[1]
  end

  # METS
  def xml_structmap_helper(given_node, xml)
    # TODO: TYPE is actually the type of the node (chapter, article, page, track, segment, section etc)
    # "TYPE" => "toc_node",
    xml.mets :div, "LABEL" => given_node.description, "ORDER" => given_node.position, "DMDID" => "ADM#{given_node.digital_file.try(:id)}" do
      # "FILEID" is actually the id of the file element in the mets document
      xml.mets :fptr, "FILEID" => "FID#{given_node.digital_file.try(:id)}"
      if given_node.children.any?
        given_node.children.each{|node| self.send(__method__, node, xml) }
      end
    end
  end

  def xml_metadata_helper(options={})
    options.assert_required_keys :entity_object, :namespace, :metadata_standard_name, :xml

    entity_object           = options[:entity_object]
    namespace               = options[:namespace]
    metadata_standard_name  = options[:metadata_standard_name]
    xml                     = options[:xml]

    entity_object.to_metadata_standard(metadata_standard_name).each do |namespaced_element, values|
      namespace, element = namespaced_element.split(':')
      [values].flatten.each do |value|
        if value.is_a? Struct and value.requires_hostaddress_from_request
          # eval is required when the namespace is dynamic - you can't do xml.send(...)
          eval "xml.#{namespace} :#{element}, \"#{request.protocol + request.host_with_port + value.absolute_path}\""
        else
          eval "xml.#{namespace} :#{element}, \"#{value.to_s.gsub(/\"/, "\"\"")}\""
        end
      end
    end
  end

end

