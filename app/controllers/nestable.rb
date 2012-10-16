require 'pp'

module Nestable

  private

  def trigger_params(*additional_triggers)
    @trigger_params ||= (["add_associated_models", "selected_institution_id", "update_form"]+additional_triggers).
                        uniq.
                        collect{|param| [param, "#{param.to_s}.x", "#{param.to_s}.y"]}.
                        flatten
  end

  def trigger_param_present?
    (params.keys & trigger_params).any?
  end

  def clean_params
    if current_object_params.present?
      current_object_params.delete_if{|k,v| k == 'identifier'}
    end
  end

  def properties_with_vocabularies
    @properties ||= controller_name.classify.constantize.properties_with_vocabularies_for_views_all
  end

  def properties_ids_with_vocabularies
    @properties_ids ||= properties_with_vocabularies.collect(&:id).flatten.uniq.compact
  end

  def vocabularies_ids
    @vocabularies_ids ||= properties_with_vocabularies.collect(&:vocabulary_id).flatten.uniq.compact
  end

  def terms
    @terms ||= Term.all(:include => :vocabulary, :conditions => {:vocabulary_id => vocabularies_ids, :visible => true})
  end

  def select_keys(hash, *keys)
    Hash[*hash.select{|k,v| [keys].flatten.include?(k)}.flatten]
  end

  def select_nested_attr(hash, conditions)
    Hash[*hash.select{|k,attrs| conditions.map{|attr,v| attrs[attr] == v}.all? }.flatten]
  end

  # TODO: move to model entity_terms
  def entity_terms
    @entity_terms ||= find_and_update_association(:association_name => 'entity_terms')
  end

  # TODO: move to model find_and_update_association
  def find_and_update_association(opts={})
    association_name = opts[:association_name]
    current_object.send(association_name.to_sym).
                   compact.
                   each {|record| record.destroy if record.marked_for_destruction? }.
                   delete_if {|record| record.marked_for_destruction? }
  end

  # TODO: move to model find_entity_terms_grouped
  def find_entity_terms_grouped(force=false)
    entity_terms_hash = {}
    properties_with_vocabularies.each do |p|
      entity_terms_hash[p] = entity_terms.select{|et| et.property_id == p.id}.uniq
    end
    entity_terms_hash
  end

  # TODO: move to model entity_terms_grouped
  def entity_terms_grouped(force=false)
    if force
      @entity_terms_grouped = find_entity_terms_grouped(force)
    else
      @entity_terms_grouped ||= find_entity_terms_grouped(force)
    end
  end

  # TODO: move to model related_terms_ids
  def related_terms_ids
    @related_terms_ids ||= entity_terms.map(&:term_id)
  end

  # TODO: move to model related_terms
  def related_terms
    @related_terms ||= terms.select{|t| related_terms_ids.include? t.id}
  end

  # TODO: move to model memoize_terms_attrs
  def memoize_terms_attrs
    current_object.entity_terms.each do |entity_term|
      related_term = related_terms.select{|t| t.id == entity_term.term_id}.first
      if related_term
        entity_term.term_code, entity_term.term_it, entity_term.term_en = related_term.code, related_term.it, related_term.en
      elsif entity_term && entity_term.term && entity_term.term.new_record? &&
            (entity_term.term.it || entity_term.term.en || entity_term.term.code)
        entity_term.term_is_new_record = true
        entity_term.term_it = entity_term.term.it
        entity_term.term_en = entity_term.term.en
        entity_term.term_code = entity_term.term.code
        entity_term.term_vocabulary_id = entity_term.term.vocabulary_id
        entity_term.term_user_id = current_user.id
        entity_term.term_translation_coalesce = (entity_term.term.it || entity_term.term.en || entity_term.term.code)
      else
        entity_term.term_code = "-- term missing --"
      end
    end
  end

  def manage_form
    entity_terms_grouped
    terms
    memoize_terms_attrs

    respond_to do |format|
      if trigger_param_present?
        format.html { render :action => if current_object.new_record? then 'new' else 'edit' end}
      elsif current_object.valid?
        current_object.save
        flash[:notice] =  t(  (if action_name == 'create' then :created_successfully else :updated_successfully end),
                              :scope => default_i18n_controllers_scope)
        format.html { redirect_to(current_object) }
        format.xml  { render :xml => current_object, :status => (if current_object.new_record? then :created else :updated end), :location => current_object }
      else
        format.html { render :action => if action_name == 'create' then 'new' else 'edit' end}
        format.xml  { render :xml => current_object.errors, :status => :unprocessable_entity }
      end
    end
  end

end

