# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include EntityTermsFormHelper

  def on?(page_name)
    "on" if controller.controller_name == page_name
  end

  def content_layout(layout_name)
    content_for(:content_layout) { layout_name }
  end

  def formatted_localized_partial_date(object, field_name)
    case object.send("#{field_name}_format".to_sym)
      when 'Y'
        localize(object.send(field_name.to_sym), :format => :only_year)
      when 'YM'
        localize(object.send(field_name.to_sym), :format => :full_month_name_and_year)
      when 'YMD'
        localize(object.send(field_name.to_sym), :format => :long)
      else
        localize(object.send(field_name.to_sym), :format => :long)
    end
  end

  def flash_notice_helper
    flash_notice = ""
    flash_notice << flash[:notice].to_s if flash[:notice]
    if flash_notice.empty?
      nil
    else
      content_tag(:p, :class => 'notice'){flash_notice}
    end
  end

  # markers
  def requirement_marker(requirement=nil)
    case requirement
      when 'mandatory'
        " <span class=\"marker\">*</span>"
      when 'recommended'
        ""
      when 'optional'
        ""
      when 'automatic'
        ""
    end
  end

  def help_marker(options={})
    # FIXME: trovare soluzione meno sporca di n &nbsp;
    help_text = t(options[:property], :scope => (options[:scope] || default_help_views_scope))
    " " + content_tag(:span, :class => "tooltip ui-icon ui-icon-info", :title => help_text) do
            '&nbsp;' * 4
          end
  end

  def default_i18n_views_scope
    [:activerecord, :attributes, controller_name.singularize.to_sym]
  end

  def default_help_views_scope
    [:help, controller_name.singularize.to_sym]
  end

  def generic_error_message_for(current_object)
    if current_object.errors.count > 0
      content_tag :p, :class => 'alert' do
        content_tag(:span, :class => "ui-icon ui-icon-alert"){} + t(:generic_error, :scope => :activerecord)
      end
    end
  end

  def generic_error_message(message=nil)
    content_tag(:p, :class => 'alert'){content_tag(:span, :class => 'ui-icon ui-icon-alert'){} + message} if message
  end

  def link_to_all(options={})
    options.assert_required_keys(:condition)
    options.assert_valid_keys(:condition)

    if options[:condition]
      link_to(t('.list_all'), self.send(:"#{controller_name}_path"))
    end
  end

  def default_size(html_element=nil)
    case html_element.to_sym
      when (:text_field or :password_field)
        "70"
      when :text_area
        "70x20"
    end
  end

  def row_label(opts={})
    content_tag(:th) do
      if opts[:label]
        opts[:label].to_s + opts[:punctuation]
      else
        t(opts[:property].to_sym, :scope => default_i18n_views_scope) + opts[:punctuation]
      end
    end
  end

  def show_row_content(obj, opts={})
    content_tag(:td, :class => opts[:css_class]) do
      if opts[:content]
        opts[:content]
      elsif obj.send(opts[:property].to_sym).to_s.blank? || obj.send(opts[:property].to_sym).blank?
        content_tag(:span, :class => "blank-record"){"[" + t(:blank_record, :scope => :application) + "]"}
      else
        h obj.send(opts[:property].to_sym)
      end
    end
  end

  def show_row_for(obj, opts={})
    content_tag :tr do
      String.new.tap do |str|
        str << row_label(opts.merge({:punctuation => ":"}))
        str << show_row_content(obj, opts)
        str << content_tag(:td, opts[:command]) if opts[:command]
      end
    end
  end

  def label_with_markers(opts={})
    f = opts[:f]
    error_message = f.error_message_on(opts[:property].to_sym, :css_class => 'fieldWithErrors')

    label_content = t opts[:property], :scope => (opts[:scope] || default_i18n_views_scope)
    label_content << requirement_marker(opts[:requirement]).to_s if opts[:requirement]
    label_content << help_marker(:property => opts[:property]).to_s if opts[:help]
    if opts[:error_message] && error_message.present?
      label_content << tag(:br) + error_message
    end

    f.label(opts[:property], label_content, :class => opts[:requirement])
  end

  def conditions_to_delete?(given_object, &block)
    yield given_object
  end

  def delete_link(*objects, &block)
    target = link_target(*objects)

    deletable = if block_given? then conditions_to_delete?(objects.last, &block) else true end

    if deletable
      link_to image_tag("trash.png"),
              target,
              :confirm => t(:confirm_deletion, :scope => [:application]),
              :method => :delete,
              :class => "del",
              :title => t(:delete, :scope => [:application])
    else
      ""
    end
  end

  def edit_link(obj, opts={})
    text        = opts[:text] || t('.edit_link')
    path        = opts[:path] || send("edit_#{obj.class.name.tableize.singularize}_path".to_sym, obj)
    authorized  = current_user_can?(:edit, obj.class.name.tableize.singularize.to_sym, obj)
    editable =  if block_given?
                  authorized && yield(obj)
                else
                  authorized
                end
    if editable
      link_to text, path, :title => t(:edit, :scope => [:application]), :class => "edit-link"
    else
      ""
    end
  end

  def admin_tag(element, content, options=nil)
    content_tag element.to_sym, content, options if current_user && (current_user >= admin or current_user == end_user)
  end

  def content_with_error_for_association(error_on_field, content)
    if error_on_field
      content_tag(:div, content, options = {:class => 'fieldWithErrors'}, escape = true)
    else
      content
    end
  end

  def precondition_counts(*entities)
    if entities && entities.any?
      entities.map{|ent| ent.classify.constantize.count }.all?{|count| count > 0}
    else
      true
    end
  end

  def current_user_can?(action_name, entity_name, given_object=nil, opts={})
    opts.assert_valid_keys :only_if_any
    checks = []
    checks << is_owner?(:controller_name => entity_name.to_s.tableize,
                        :authorizable_object => given_object || entity_name.to_s.classify.constantize.new,
                        :authorizable_action => action_name.to_s)
    checks << precondition_counts(*opts[:only_if_any])
    checks.all?
  end

  def count_for_current_user(entity_name)
    if current_user >= admin or current_user <= end_user
      entity_name.to_s.classify.constantize.count
    else
      current_user.institution.send(:"#{entity_name.to_s.tableize}_count").to_i
    end
  end

  # example # => # <%= link_to_by_role @digital_collection, :title, :edit, t('.edit_link') %>
  def link_to_by_role(object, property, action, text=nil)
    text ||= object.send(property.to_sym)
    if is_owner?(:authorizable_object => object, :authorizable_action => action.to_s)
      link_to text, self.send("#{action.to_s}_#{object.class.name.underscore}_path", object)
    else
      ""
    end
  end

  # returns the downcase singular name of the class of an object if is a model, otherwise the argument
  def object_class_name(obj)
    if obj.is_a? ActiveRecord::Base
      obj.class.name.tableize.singularize
    else
      obj.to_s
    end
  end

  # returns the correct target object or objects for link to nested resources
  def link_target(*objects)
    objects = objects.select{|obj| obj.is_a?(ActiveRecord::Base) }
    if objects.count > 1
      objects
    else
      objects.first
    end
  end

  # example 1 (in project/show):
  # auth_nested_link  t('.linked_digital_collections', :count => @project.digital_collections.size), @project, :digital_collection, :index
  # => 1 collezione collegata
  # example 2 (in project/show):
  # auth_nested_link  t('.new_linked_digital_collection'), @project, :digital_collection, :new
  # => Nuova collezione collegata
  def auth_nested_link(text, referenced, dependent, action, options={})
    referenced_name, dependent_name = *[referenced, dependent].map{|obj| object_class_name(obj)}
    target = link_target(referenced, dependent)
    path_type = options[:path] || "path"

    path = if action.to_s == "index"
      "#{referenced_name}_#{dependent_name.tableize.classify.tableize}_#{path_type}"
    else
      "#{action}_#{referenced_name}_#{dependent_name}_#{path_type}"
    end

    if referenced && dependent && current_user_can?(action.to_sym, dependent_name.to_sym)
      link_to text, self.send(path, target), options
    else
      ""
    end
  end

  def error_on_field(formbuilder, property)
    formbuilder.object.send(:"#{property.name}_error")
  end

  def terms_option_list_for_property(terms, prop)
    property_terms = @terms.select{|t| t.vocabulary_id == prop.vocabulary_id}.sort_by(&:translation_coalesce)
    options_for_select(property_terms.map{|term| [term.translation_coalesce, term.id]}, selected = nil )
  end

  def terms_select_for_property(form_builder, terms, property)
    form_builder.select :term_id,
                        terms_option_list_for_property(terms, property),
                        options = {:include_blank => t(:please_select, :scope => [:application])}
  end

  def entity_terms_grouped
    instance_variable_get("@entity_terms_grouped".to_sym)
  end

  def fields_for_property(f, prop_name)
    prop, ets = *entity_terms_grouped.select{|prop, ets| prop.name.to_s == prop_name.to_s }.flatten(1)
    if prop && ets
      if prop.cardinality == 'one'
        render  :partial => "shared/fields_for_models_associated_with_has_one",
                :locals => {:f => f, :property => prop, :entity_terms => ets}
      elsif prop.cardinality == 'many'
        render  :partial => "shared/fields_for_models_associated_with_has_many",
                :locals => {:f => f, :property => prop, :entity_terms => ets}
      end
    end
  end

  def show_row_for_property(prop_name)
    prop, ets = *entity_terms_grouped.select{|prop, ets| prop.name.to_s == prop_name.to_s }.flatten(1)
    if prop && ets
      if prop.cardinality == 'one'
        render  :partial => "shared/show_models_associated_with_has_one",
                :locals => {:property => prop, :entity_terms => ets}
      elsif prop.cardinality == 'many'
        render  :partial => "shared/show_models_associated_with_has_many",
                :locals => {:property => prop, :entity_terms => ets}
      end
    end
  end

  def field_activator_for(obj, property, opts={})
    content = opts[:content] || t(:activate_field, :scope => [:application])
    css_class = opts[:css_class] || "activate-field"
    link_to content, "#nogo", :class => css_class, "data-related" => "#{obj.class.name.tableize.singularize}[#{property}]"
  end

  def current_sort?(column, default=false)
    (params[:sort].blank? && default) || params[:sort] == column.to_s
  end

  def sort_css_class(column, default)
    direction = sort_direction(column)
    "current #{direction}" if current_sort?(column, default)
  end

  def sort_direction(column)
    (current_sort?(column) && params[:direction] == "desc") ? "asc" : "desc"
  end

  def sort_link_to(column, text, opts={})
    link_to text,
            params.delete_if{ |key, value| key == "institution_id" }. # Mantiene URL pulito
            merge({:sort => column.to_s, :direction => sort_direction(column)}),
            {:class => sort_css_class(column, opts[:default])}
  end

  # FIXME: semplificare e rendere più funzionale
  def filter_links_by( param, opts={} )
    all = "".tap do |s|
      s <<  if params[param].present?
              link_to opts[:all][:txt], Hash[*params.select{|k,v| k != param.to_s}.to_a.flatten]
            else
              content_tag :strong, opts[:all][:txt]
            end
      s << " (#{opts[:all][:count].to_i})"
    end

    alternatives = opts[:alternatives].map do |alt|
      "".tap do |s|
        s <<  if params[param] == alt[:value]
                content_tag :strong, alt[:txt]
              else
                link_to alt[:txt], params.merge({param => alt[:value], :page => 1})
              end
        s << " (#{alt[:count].to_i})"
      end
    end

    [all, *alternatives].join("&nbsp;|&nbsp;")
  end

  # Required options:
  # - <tt>:f</tt> => main entity form builder
  # - <tt>:related_to</tt> => a symbol of the name of the target association,
  #   example :creators if Fond has many creators through :rel_creator_fonds
  # - <tt>:related_through</tt> => a collection of the current association records,
  #   example @rel_creator_fonds (array of active record objects),
  #   if Fond has many creators through :rel_creator_fonds;
  #   if this local is not specified, an instance variable will be used, based
  #   on the name of the through association
  # - <tt>:selected_label</tt> => a lambda used to populate the visible value of every single related object;
  #   the association record is yielded to the block;
  #   this is required because in general retrieving the shown value is not trivial,
  #   and is specific to every type of association
  #   example: lambda { |through_record| through_record.creator.preferred_name.try(:name) }
  # - <tt>:available_related</tt> => the number of records available to be added to the relation
  #
  # Other requirements:
  # - the target model (Creator, for example), must have a method (or, preferably, a scope)
  #   that accepts a search string, which is given in params[:term]
  #
  # Other options with defaults:
  # - <tt>:foreign_key</tt>, if provided, it will override the default (that is association_foreign_key)
  # - <tt>:excluded_ids</tt>, an id or an array of ids; if provided the records with these
  #   ids will be filtered out, and not be shown in the autocomplete or in the suggested list,
  #   even if present in the results;
  # - <tt>:cardinality</tt>, default 'unlimited', can be set at 1
  # - <tt>:suggested_list</tt>, if provided, will be used to create a list of preset suggestions
  # - <tt>:suggested_label</tt>, same principle of selected_label
  # - <tt>:suggested_threshold</tt>, required if :suggested_list have been specified, if
  #   the suggested_list size is greater than this, autocomplete will be used
  # - <tt>:autocompletion_controller</tt>, default is the same of the "related_to" option
  #   (example: "creators")
  # - <tt>:autocompletion_action</tt>, default is "list";
  #   the action must return a json response, with an array of objects, and each
  #   object must have the property "id" and "value";
  #   id is the id of the target association (creator, for example)
  def finalize_relation_options(f, relation_options)
    opts = relation_options
    # Parameters setup, based on given locals
    #
    # Example: related_to => :creators
    opts[:association]                = f.object.class.reflect_on_association(opts[:related_to].to_sym)
    # :related_model => Creator
    opts[:related_model]              = opts[:association].klass
    # :related_model_name => "creator"
    opts[:related_model_name]         ||= opts[:related_model].name.underscore
    # :foreign_key => "creator_id"
    opts[:foreign_key]                ||= opts[:association].association_foreign_key
    opts[:through_association]        = opts[:association].through_reflection
    # :through_association_name => :rel_creator_fonds
    opts[:through_association_name]   = opts[:through_association].name
    # :through_model => RelCreatorFond
    opts[:through_model]              = opts[:through_association].klass
    # :through_record => rel_creator_fond (new_record? => true)
    opts[:through_record]             = opts[:through_model].new # to support the template item
    # :source_association_name => :creator
    opts[:source_association_name]    = opts[:association].source_reflection.name
    # :related_through => @rel_creator_fonds, should always be specified to use local
    opts[:related_through]            ||= instance_variable_get("@#{opts[:through_association_name]}".to_sym)
    # => "creators"
    opts[:autocompletion_controller]  ||= opts[:related_to].to_s
    opts[:autocompletion_action]      ||= "list"
    opts[:variant]                    ||= 'autocomplete'
    opts[:excluded_ids]               ||= []
    opts[:cardinality]                ||= 'unlimited'
    opts[:available_related]          ||= nil
    opts[:child_index]                ||= '_new_' # to support the template item
    opts[:through_hidden_fields]        = opts[:through_association].options[:conditions].
                                          merge(opts[:through_hidden_fields] || {})
    opts[:title]                      ||= t("activerecord.models.#{opts[:related_model_name]}",
                                            :count => opts[:cardinality].to_i)
    opts[:suggested_threshold]        ||= nil
    opts[:suggested_list]             ||= nil
    opts[:selected_label]             ||= nil
    opts[:selected_label_short]       ||= nil
    opts[:selected_label_full]        ||= nil
    opts[:fields_before]              ||= nil
    opts[:fields_after]               ||= nil
    opts[:new_related_partial]        ||= nil
    opts[:new_related_locals]         ||= {} if opts[:new_related_partial]
    opts[:new_related_controller]     ||= opts[:autocompletion_controller]
    opts[:new_related_action]         ||= 'new'
    opts[:new_related_common_params]  ||= opts[:through_hidden_fields]
    opts[:unique_identifier]            = ActiveSupport::SecureRandom.hex
    opts[:requirement]                ||= 'optional'
    opts[:search_placeholder]           = opts.key?(:search_placeholder) ? opts[:search_placeholder] : true
    opts[:search_invite]                = opts.key?(:search_invite) ? opts[:search_invite] : false
    opts[:title_tooltip]              ||= nil
    opts[:select_prompt]              ||= ''
    if opts[:suggested_list]
      opts[:options_for_select]       ||= opts[:suggested_list].map do |record|
                                            [opts[:suggested_label].call(record), record.id]
                                          end.unshift([opts[:select_prompt], nil])
    end
    opts[:suggested_partial]          ||= "shared/relations/suggested"
    opts[:selected_partial]           ||= opts.key?(:selected_partial) ? opts[:selected_partial] : "shared/relations/selected"
    opts[:item_partial]               ||= "shared/relations/item"
    opts[:input_partial]              ||= "shared/relations/#{opts[:variant]}/input"

    opts
  end

  def default_relation_options_for( f, related_to, related_through )
    {
      :related_to => related_to.to_sym,
      :related_through => related_through,
      :suggested_list => instance_variable_get("@suggested_#{related_to}".to_sym),
      :suggested_threshold => instance_variable_get("@#{related_to}_threshold".to_sym),
      :available_related => instance_variable_get("@available_#{related_to}".to_sym)
    }
  end

  def render_relation_for( f, related_to, related_through, opts={} )
    render  :partial => "shared/relations/relation",
            :locals => {
              :f => f,
              :relation_options => default_relation_options_for(f, related_to, related_through).merge(opts)
            }
  end

end

