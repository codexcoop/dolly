module EntityTermsFormHelper

  def fields_for_models_associated_with_has_many(f, property, entity_terms)
    content_tag :div, :class => "property", "data-property-id" => property.id do
      "".tap do |s|
        s << "\n" + content_with_error_for_association(error_on_field(f, property), label_tag("", property.send("human_#{I18n.locale.to_s}")))
        s << "\n" + requirement_marker(property.requirement)
        s << "\n" + help_marker(:property => property.name.tableize.to_sym)
        s << "\n" + content_tag(:div, :class => "terms-selection") do
          "".tap do |s1|
            s << "\n" + assigned_entity_terms(f, property, entity_terms)
            s << "\n" + entity_term(f, property)
            s << "\n" + content_tag(:p) do
              content_tag :a, :href => "#nogo", :class => "select-value", "data-property-id" => property.id do
                "+ seleziona un altro termine"
              end
            end
          end
        end
        s << "\n" + content_tag(:div, :class => "terms-addition") do
          create_and_add_new_term(f, property)
        end
      end
    end
  end

  def assigned_entity_terms(f, property, entity_terms)
    content_tag :ul, "data-property-id" => property.id do
      entity_terms.map do |entity_term|
        content_tag :li, :class => "property_#{property.id} already-assigned-terms" do
          "".tap do |s|
            f.fields_for :entity_terms, entity_term do |entity_term_form|
              # MEMOIZATION
              if property.vocabulary_is_user_editable && entity_term.term_is_new_record
                s << "\n" + entity_term_form.hidden_field(:term_is_new_record, :value => '1')
                entity_term_form.fields_for :term, entity_term.build_term do |term_form|
                    s << "\n" + term_form.hidden_field(:vocabulary_id, :value => entity_term.term_vocabulary_id)
                    s << "\n" + term_form.hidden_field(:it, :value => entity_term.term_it)
                    s << "\n" + term_form.hidden_field(:en, :value => entity_term.term_en)
                    s << "\n" + term_form.hidden_field(:code, :value => entity_term.term_code)
                    s << "\n" + term_form.hidden_field(:user_id, :value => entity_term.term_user_id)
                end
              end
              s << "\n" + entity_term_form.hidden_field(:term_id)
              s << "\n" + entity_term_form.hidden_field(:vocabulary_id)
              s << "\n" + entity_term_form.hidden_field(:property_id)
              s << "\n" + entity_term_form.label(:_destroy, (image_tag "icons/remove.png", :alt => "Remove this term"))
              s << "\n" + entity_term_form.check_box(:_destroy)
              s << "\n" + entity_term_form.label(:_destroy, h(entity_term.term_translation_coalesce))
            end
          end
        end
      end
    end
  end

  def error_on_field(f, property)
    f.object.send(:"#{property.name}_error")
  end

  def new_entity_term(f, property)
    f.object.entity_terms.build(
      :vocabulary_id => property.vocabulary_id,
      :property_id => property.id
    )
  end

  def entity_term(f, property)
    content_tag  :p, :class => 'terms-list', 'data-property-id' => property.id do
      "".tap do |s|
        f.fields_for :entity_terms, new_entity_term(f, property) do |entity_term_form|
          s << "\n" + entity_term_form.hidden_field(:vocabulary_id)
          s << "\n" + entity_term_form.hidden_field(:property_id)
          s << "\n" + content_with_error_for_association(
                        error_on_field(f, property),
                        terms_select_for_property(entity_term_form, @terms, property)
                      )
        end
      end
    end
  end

  def create_and_add_new_term(f, property)
    if property.vocabulary_is_user_editable?
      "".tap do |s|
        f.fields_for :entity_terms, new_entity_term(f, property) do |entity_term_form|
          s << "\n" + content_tag(:p) do
            content_tag(:a, :href => "#nogo", :class => "add-value", "data-property-id" => property.id) do
              "+ crea e associa un nuovo termine"
            end
          end
          s << "\n" + content_tag(:p, :class => "new-value", "data-property-id" => property.id) do
            "".tap do |s1|
              s1 << "\n" + entity_term_form.hidden_field(:vocabulary_id)
              s1 << "\n" + entity_term_form.hidden_field(:property_id)
              entity_term_form.fields_for :term, entity_term_form.object.build_term(:vocabulary_id => vocabulary_id) do |term_form|
                s1 << "\n" + term_form.hidden_field(:user_id, :value => current_user.id)
                s1 << "\n" + term_form.hidden_field(:vocabulary_id)
                s1 << "\n" + term_form.text_field(:it, :size => 20)
              end
            end
          end
        end
      end
    end
  end

end

