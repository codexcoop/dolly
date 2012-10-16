require 'zoom'

class OriginalObjectsController < ApplicationController
  # TODO: I18n in tutto il controller
  include Nestable
  include CustomSqlConditions

  before_filter :require_user
  before_filter :clean_params

  before_filter :only => [:new, :create, :edit, :update, :destroy] do |controller|
    controller.original_object
    controller.require_role('editor')
  end

  def original_object
    @original_object ||=  if params[:id]
                            OriginalObject.find(params[:id])
                          else
                            OriginalObject.new
                          end
  end

  def index
    additional_conditions = {}
    if params[:institution_id]
      additional_conditions.update({:institution_id => params[:institution_id]})
    end
    if current_user < admin && current_user > end_user
      additional_conditions.update({:institution_id => current_user.institution_id})
    end
    if params[:digital_collection_id]
      original_object_ids = OriginalObject.find(
        :all,
        :select => "original_objects.id",
        :joins => {:digital_objects => :digital_collection},
        :conditions => {:digital_collections => {:id => params[:digital_collection_id]}}
      ).map(&:id)
      additional_conditions.update(:id => original_object_ids)
    end

    @original_objects = find_original_objects(additional_conditions)
    institution
    @total_count = OriginalObject.for_user(current_user).count
    @digital_collection = DigitalCollection.find(params[:digital_collection_id]) if params[:digital_collection_id].present?

    OriginalObject.set_dynamic_digital_objects_count(@original_objects)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @original_objects }
    end
  end

  def show
    original_object

    @digital_objects_count = DigitalObject.count(:conditions => {:original_object_id => original_object.id})
    digital_collection_ids =  DigitalCollection.find(
                                :all,
                                :select => "digital_collections.id",
                                :joins => {:project => :institution},
                                :conditions => {:institutions => {:id => original_object.institution_id}}
                              ).
                              map(&:id)
    @digital_collections_count = DigitalCollection.count(:conditions => {:id => digital_collection_ids})

    entity_terms_grouped
    memoize_terms_attrs

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @original_object }
    end
  end

  # TODO: use rails-native rescue_from instead of rescue_from_unimarc_format_errors
  def rescue_from_unimarc_format_error(message_for_alert, error_message)
    puts error_message
    redirect_to new_catalogue_search_url
    add_to_alert(message_for_alert)
  end

  # FIXME: submit di "Incolla record Unimarc" va in errore se form vuota
  def initialize_with_unimarc
    unimarc_text = params[:unimarc_text].sub(/<pre>/,'').sub(/<\/pre>/,'')
    if unimarc_text.blank?
      rescue_from_unimarc_format_error(t '.provide_unimarc', :scope => default_i18n_controllers_scope)
    else
      begin
        @original_object = OriginalObject.new.initialize_with_unimarc(unimarc_text)
        setup_relation_collections
        render :action => 'new'
      rescue Unimarc::ParsingException => e
        rescue_from_unimarc_format_error(t('.unimarc_format_error', :scope => default_i18n_controllers_scope), e.message)
      end
    end
  end

  def new
    original_object
    setup_relation_collections

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @original_object }
    end
  end

  def edit
    original_object
    setup_relation_collections
  end

  def create
    params[:original_object][:institution_id] = current_user.institution_id

    original_object.attributes = params[:original_object]
    original_object.user_id = current_user.id

    # TODO: using javascript this should not be required anymore
    trigger_params "add_associated_models", "selected_institution_id"

    respond_to do |format|
      if original_object.save
        format.html { redirect_to original_object_url(original_object) }
      else
        setup_relation_collections
        format.html { render :action => 'new' }
      end
    end
  end

  def update
    params[:original_object][:institution_id] = current_user.institution_id unless current_user >= admin

    clean_params

    original_object.attributes = params[:original_object]
    original_object.user_id = current_user.id unless original_object.user_id? && current_user >= admin

    # TODO: using javascript this should not be required anymore
    trigger_params "add_associated_models", "selected_institution_id"

    respond_to do |format|
      if original_object.save
        format.html { redirect_to original_object_url(original_object) }
      else
        setup_relation_collections
        format.html { render :action => 'edit' }
      end
    end
  end

  def destroy
    original_object.destroy
    flash[:notice] = t :deleted_successfully, :scope => default_i18n_controllers_scope

    respond_to do |format|
      format.html { redirect_to(original_objects_url) }
      format.xml  { head :ok }
    end
  end

  def original_objects_preview_list
    @original_objects_preview_list =
      if current_user == admin && params[:institution_id]
        Institution.find(params[:institution_id]).original_objects
      elsif current_user == admin
        OriginalObject
      else
        current_user.institution.original_objects
      end.
      find(:all, :conditions => ajax_search_conditions, :limit => 10, :order => "original_objects.title")
  end

  def ajax_search
    @current_original_object = original_object
    original_objects_preview_list

    respond_to do |format|
      # use :locals
      format.html { render :partial => 'preview_list' }
    end

  end

  def associations
    @associations_to = original_object.associations_to.find(:all, :include => [:related_original_object])
  end

  def create_association
    original_object
    association = Association.new(params[:association])

    respond_to do |format|
      if association.save
        flash[:notice] = "Collegamento creato con successo"
        format.xml  { head :ok }
      else
        flash[:notice] = "Errore nella creazione del collegamento"
        format.xml  { render :xml => association.errors, :status => :unprocessable_entity }
      end
      format.html { redirect_to(associations_original_object_url(original_object)) }
    end
  end

  def destroy_association
    association = Association.find(params[:association_id])
    original_object

    association.destroy
    flash[:notice] = "Collegamento eliminato con successo"

    respond_to do |format|
      format.html { redirect_to(associations_original_object_url(original_object)) }
      format.xml  { head :ok }
    end
  end

  private

  def ajax_search_conditions
    searched_title = params[:query].downcase.strip.squeeze(' ')
    conditions = []
    conditions <<  [ "NOT id = ?", original_object.id ] if params[:id].present?
    #conditions <<  search_conditions_for(OriginalObject, :title, :main_related_title, :param_key => :query)
    conditions <<  search_conditions_for(OriginalObject, :title, :param_key => :query)
    OriginalObject.merge_conditions(*conditions)
  end

  def institutions
    @institutions ||= if current_user >= admin
                        Institution.all
                      elsif current_user >= editor
                        [current_user.institution]
                      else
                        nil
                      end
  end

  def institution
    @institution ||= if original_object and original_object.institution
                        original_object.institution
                      elsif params[:institution_id].present?
                        Institution.find(params[:institution_id])
                      else
                        current_user.institution
                      end
  end

  # TODO: move to model/named scope
  def find_original_objects(additional_conditions={})
    OriginalObject.all({
      :include => [:institution, :digital_objects],
      :select => "original_objects.id,
                  original_objects.title,
                  original_objects.institution_id,
                  original_objects.string_date,
                  original_objects.main_association_qualifier,
                  original_objects.main_related_title,
                  original_objects.updated_at,
                  coalesce(original_objects.main_related_title || original_objects.title, original_objects.title) AS ordering_title",
      :conditions =>  OriginalObject.merge_conditions(
                        additional_conditions,
                        search_conditions_for(OriginalObject, :title, :main_related_title, :param_key => :title)
                      ),
      :order => sort_string(params[:sort], 'ordering_title')
    }).
    paginate(:page => params[:page], :per_page => OriginalObject.per_page)
  end

  def clean_params
    super
    # TODO: verify if can be removed safely, interference with pagination
    #params[:institution_id] = current_user.institution_id unless current_user >= admin or current_user <= end_user
    params[:original_object].delete_if{|k,v| k == 'identifier'} if params[:original_object].present?
  end

  def setup_relation_collections
    return unless @original_object

    relation_collections  :related => "object_types", :through => "original_object_object_types",
      :suggested => lambda { Term.object_types }

    relation_collections  :related => "subjects", :through => "original_object_subjects"

    relation_collections  :related => "creators", :through => "original_object_creators"

    relation_collections  :related => "contributors", :through => "original_object_contributors"

    relation_collections  :related => "publishers", :through => "original_object_publishers"

    relation_collections  :related => "languages", :through => "original_object_languages",
      :suggested => lambda { Term.languages }

    relation_collections  :related => "coverages", :through => "original_object_coverages"
  end

end

