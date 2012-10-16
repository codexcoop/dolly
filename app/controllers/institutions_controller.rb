class InstitutionsController < ApplicationController
  before_filter :require_user
  before_filter :define_shared_instance_variables, :except => [:index]

  before_filter :only => [:edit, :update] do |controller|
    controller.require_role 'institution_admin'
  end

  before_filter :only => [:new, :create, :destroy] do |controller|
    controller.require_role 'admin'
  end

  before_filter :only => [:index, :show] do |controller|
    controller.require_role 'end_user'
  end

  def define_shared_instance_variables
    @institution  = if params[:id]
                      Institution.find(params[:id])
                    elsif params[:institution]
                      Institution.new(params[:institution])
                    else
                      Institution.new
                    end
  end

  def index
    if current_user >= admin or current_user <= end_user
      @institutions = Institution.all(:order => "name")
    else
      []
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @institutions }
    end
  end

  def show
    @institution ||= Institution.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @institution }
    end
  end

  def new
    @institution ||= Institution.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @institution }
    end
  end

  def edit
    @institution ||= Institution.find(params[:id])
    @updating = true
  end

  def create
    @institution ||= Institution.new(params[:institution])
    @institution.user_id = current_user.id

    respond_to do |format|
      if @institution.save
        flash[:notice] = t :created_successfully, :scope => default_i18n_controllers_scope
        format.html { redirect_to(@institution) }
        format.xml  { render :xml => @institution, :status => :created, :location => @institution }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @institution.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @institution ||= Institution.find(params[:id])
    @institution.user_id = current_user.id

    respond_to do |format|
      if @institution.update_attributes(params[:institution])
        flash[:notice] = t :updated_successfully, :scope => default_i18n_controllers_scope
        format.html { redirect_to(@institution) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @institution.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @institution ||= Institution.find(params[:id])
    @institution.destroy
    flash[:notice] = t :deleted_successfully, :scope => default_i18n_controllers_scope

    respond_to do |format|
      format.html { redirect_to(institutions_url) }
      format.xml  { head :ok }
    end
  end
end

