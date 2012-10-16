class DigitalCollectionsController < ApplicationController

  include Nestable

  before_filter :require_user
  before_filter :clean_params

  before_filter :only => [:index, :show] do |controller|
    controller.digital_collection
    controller.require_role('end_user')
  end

  before_filter :except => [:index, :show] do |controller|
    controller.digital_collection
    controller.require_role('institution_admin')
  end

  def digital_collection
    @digital_collection ||= if params[:id].present?
                              DigitalCollection.find(params[:id])
                            elsif params[:project_id].present?
                              DigitalCollection.new(:project_id => project.id)
                            else
                              DigitalCollection.new
                            end
  end

  # OPTIMIZE: see custom_search named_scope in digital_object.rb model
  def index
    if (current_user >= admin or current_user <= end_user)
      if params[:project_id].present?
        @digital_collections = find_digital_collections :project_id => params[:project_id]
      else
        @digital_collections = find_digital_collections
      end
    else
      if params[:project_id]
        @digital_collections = find_digital_collections  ["projects.id = :project_id AND institutions.id = :institution_id", {:project_id => params[:project_id].to_i, :institution_id => current_user.institution_id} ]
      else
        @digital_collections = find_digital_collections  ["institutions.id = :institution_id", {:institution_id => current_user.institution_id} ]
      end
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @digital_collections }
    end
  end

  def show
    digital_collection
    @digital_objects_count = DigitalObject.count(:conditions => {:digital_collection_id => digital_collection.id})
    @original_objects_count = OriginalObject.find(
      :all,
      :joins => :digital_objects,
      :select => "original_objects.id",
      :conditions => {:digital_objects => {:id => digital_collection.digital_object_ids}}
    ).count

    digital_collection.digital_objects.find(:all, :select => "digital_objects.id, digital_objects.original_object_id")

    entity_terms_grouped
    memoize_terms_attrs

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @digital_collection }
    end
  end

  def new
    digital_collection
    project
    projects
    setup_relation_collections

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @digital_collection }
    end
  end

  def edit
    digital_collection
    projects
    setup_relation_collections
  end

  def create
    digital_collection.attributes = params[:digital_collection]
    digital_collection.user_id = current_user.id

    setup_relation_collections

    projects

    manage_form
  end

  def update
    digital_collection.user_id = current_user.id  unless digital_collection.user_id? and current_user >= admin
    digital_collection.attributes = params[:digital_collection]

    setup_relation_collections

    projects

    manage_form
  end

  def destroy
    digital_collection.destroy
    flash[:notice] = t :deleted_successfully, :scope => default_i18n_controllers_scope

    respond_to do |format|
      format.html { redirect_to(digital_collections_url) }
      format.xml  { head :ok }
    end
  end

  private

  def clean_params
    super
    params[:institution_id] = current_user.institution_id unless (current_user >= admin or current_user <= end_user)
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

  def project
    @project ||=  if params[:project_id].present?
                    Project.find(params[:project_id])
                  else
                    digital_collection.project
                  end
  end

  def institution
    @institution ||=  if project
                        project.institution
                      elsif params[:institution_id].present?
                        if institutions
                          [institutions.select{|inst| inst.id.to_s == params[:institution_id].to_s}].flatten.first
                        else
                          Institution.find(params[:institution_id])
                        end
                      else
                        current_user.institution
                      end
  end

  def projects
    @projects ||= if institution
                  institution.projects
                else
                  []
                end
  end

  # OPTIMIZE: remove include or joins
  def find_digital_collections(additional_conditions={})
    DigitalCollection.all(:include => [:digital_objects, {:project => :institution}],
                          :joins => {:project => :institution},
                          :select => "digital_collections.title, digital_collections.id, digital_collections, digital_collections.project_id",
                          :conditions => additional_conditions,
                          :order => "digital_collections.title" )
  end

  def setup_relation_collections
    return unless @digital_collection

    relation_collections  :related => "languages", :through => "digital_collection_languages",
      :suggested => lambda { Term.rfc_5646_languages }

    relation_collections  :related => "digital_formats", :through => "digital_collection_digital_formats",
      :suggested => lambda { Term.digital_formats }

    relation_collections  :related => "digital_types", :through => "digital_collection_digital_types",
      :suggested => lambda { Term.digital_types }

    relation_collections  :related => "content_types", :through => "digital_collection_content_types",
      :suggested => lambda { Term.content_types }

    relation_collections  :related => "subjects", :through => "digital_collection_subjects"

    relation_collections  :related => "accrual_methods", :through => "digital_collection_accrual_methods",
      :suggested => lambda { Term.accrual_methods }

    relation_collections  :related => "accrual_periodicities", :through => "digital_collection_accrual_periodicities",
      :suggested => lambda { Term.accrual_periodicities }

    relation_collections  :related => "accrual_policies", :through => "digital_collection_accrual_policies",
      :suggested => lambda { Term.accrual_policies }

    relation_collections  :related => "standards", :through => "digital_collection_standards",
      :suggested => lambda { Term.standards }

    relation_collections  :related => "periods", :through => "digital_collection_periods",
      :suggested => lambda { Term.periods }

    relation_collections  :related => "spatial_coverages", :through => "digital_collection_spatial_coverages",
      :suggested => lambda { Term.spatial_coverages }

    #relation_collections  :related => "civilisations", :through => "digital_collection_civilisations",
    #  :suggested => lambda { Term.civilisations }
  end

end

