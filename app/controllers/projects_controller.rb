class ProjectsController < ApplicationController

  include Nestable

  before_filter :require_user
  before_filter :clean_params

  before_filter :only => [:new, :create, :edit, :update, :destroy] do |controller|
    controller.project
    controller.require_role('institution_admin')
  end

  before_filter :only => [:show, :index] do |controller|
    controller.project
    controller.require_role('end_user')
  end

  def project
    @project ||=  if params[:id]
                    Project.find(params[:id])
                  else
                    Project.new
                  end
  end

  def index
    # TODO: use the nested resources notation in case like this if possible
    if (current_user >= admin or current_user <= end_user) and params[:institution_id].present?
      @projects = find_projects :institution_id => params[:institution_id].to_i
    elsif (current_user >= admin or current_user <= end_user)
      @projects = find_projects
    else
      @projects = find_projects :institution_id => current_user.institution_id
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @projects }
     end
  end

  def show
    project
    @digital_collections_count = DigitalCollection.count(:conditions => {:project_id => project.id})
    @digital_objects_count = DigitalObject.count(:conditions => {:digital_collection_id => project.digital_collection_ids})

    entity_terms_grouped
    memoize_terms_attrs

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @project }
    end
  end

  def new
    project
    project.institution_id = current_user.institution_id if project.new_record?

    setup_relation_collections

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @project }
    end
  end

  def edit
    project
    setup_relation_collections
  end

  def create
    clean_params

    params[:project][:institution_id] = current_user.institution_id
    params[:project][:user_id] = current_user.id

    project.attributes = params[:project]

    setup_relation_collections

    manage_form
  end

  def update
    clean_params

    params[:project][:institution_id] = current_user.institution_id unless current_user >= admin and project.institution_id?
    params[:project][:user_id] = current_user.id unless project.user_id? and current_user >= admin

    project.attributes = params[:project]

    setup_relation_collections

    manage_form
  end

  def destroy
    project.destroy
    flash[:notice] = t :deleted_successfully, :scope => default_i18n_controllers_scope

    respond_to do |format|
      format.html { redirect_to(projects_url) }
      format.xml  { head :ok }
    end
  end

  private

  def clean_params
    super
    params[:institution_id] = current_user.institution_id unless current_user >= admin or current_user <= end_user
  end

  def set_agent_id
    if not params[:agent_id].blank?
      project.agent_id = params[:agent_id]
    else
      project.agent_id = current_user.institution_id
    end
  end

  def institutions
    @institutions ||= if current_user >= admin
                        Institution.all
                      elsif current_user >= institution_admin
                        [current_user.institution]
                      else
                        nil
                      end
  end

  def institution
    @institution  ||= if @project and @project.institution
                        @project.institution
                      elsif not params[:institution_id].blank?
                        if @institutions
                          @institutions.select{|institution| institution.id == params[:institution_id]}
                        else
                          Institution.find(params[:institution_id])
                        end
                      else
                        current_user.institution
                      end
  end

  def find_projects(additional_conditions={})
    projects = Project.all(:include => [:institution, :digital_collections],
                           :select => 'projects.id, projects.institution_id, projects.title',
                           :conditions => additional_conditions,
                           :order => "projects.title")
  end

  def setup_relation_collections
    relation_collections  :related => "status", :through => "project_statuses",
      :suggested => lambda { Term.project_statuses }

    relation_collections  :related => "digitisation_process", :through => "project_digitisation_processes",
      :suggested => lambda { Term.digitisation_processes }

    relation_collections  :related => "fundings", :through => "project_fundings",
      :suggested => lambda { Term.fundings }
  end

end

