class MetadataStandardsController < ApplicationController
  before_filter :require_user

  before_filter do |controller|
    controller.require_role('admin')
  end

  def index
    @metadata_standards = MetadataStandard.find(:all, :include => [{:elements => :vocabulary}])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @metadata_standards }
    end
  end

  def show
    @metadata_standard = MetadataStandard.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @metadata_standard }
    end
  end

  def new
    @metadata_standard = MetadataStandard.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @metadata_standard }
    end
  end

  def edit
    @metadata_standard = MetadataStandard.find(params[:id])
    @updating = true
  end

  def create
    @metadata_standard = MetadataStandard.new(params[:metadata_standard])
    @metadata_standards.user_id = current_user.id

    respond_to do |format|
      if @metadata_standard.save
        flash[:notice] = t :created_successfully, :scope => default_i18n_controllers_scope
        format.html { redirect_to(@metadata_standard) }
        format.xml  { render :xml => @metadata_standard, :status => :created, :location => @metadata_standard }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @metadata_standard.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @metadata_standard = MetadataStandard.find(params[:id])
    @metadata_standards.user_id = current_user.id

    respond_to do |format|
      if @metadata_standard.update_attributes(params[:metadata_standard])
        flash[:notice] = t :updated_successfully, :scope => default_i18n_controllers_scope
        format.html { redirect_to(@metadata_standard) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @metadata_standard.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @metadata_standard = MetadataStandard.find(params[:id])
    @metadata_standard.destroy
    flash[:notice] = t :deleted_successfully, :scope => default_i18n_controllers_scope

    respond_to do |format|
      format.html { redirect_to(metadata_standards_url) }
      format.xml  { head :ok }
    end
  end
end

