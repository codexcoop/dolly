class EntitiesController < ApplicationController

  include Nestable

  before_filter :require_user
  before_filter :clean_params

  before_filter do |controller|
    controller.entity
    controller.require_role('admin')
  end

  def entity
    @entity ||= if params[:id]
                  Entity.find(params[:id])
                else
                  Entity.new
                end
  end

  def index
    @entities = Entity.find(:all, :include => [:metadata_standards, :properties])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @entities }
    end
  end

  def show
    entity

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @entity }
    end
  end

  def new
    entity

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @entity }
    end
  end

  def edit
    entity
    entity_metadata_standards
    metadata_standards_options_for_select
  end

  def create
    clean_params

    entity.attributes = params[:entity]

    entity_metadata_standards
    metadata_standards_options_for_select

    respond_to do |format|
      if params['add_metadata_standard'].present? or params['update_form'].present?
        format.html { render :action => 'new'}
      elsif entity.save
        flash[:notice] = 'Property successfully created.'
        format.html { redirect_to entity }
        format.xml  { head :ok }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => entity.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    clean_params

    entity.attributes = params[:entity]

    entity_metadata_standards
    metadata_standards_options_for_select

    respond_to do |format|
      if params['add_metadata_standard'].present? or params['update_form'].present?
        format.html { render :action => 'edit'}
      elsif entity.save
        flash[:notice] = 'Property successfully updated.'
        format.html { redirect_to entity }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => entity.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    entity.destroy
    flash[:notice] = "Entity deleted."

    respond_to do |format|
      format.html { redirect_to(entities_url) }
      format.xml  { head :ok }
    end
  end

  private

  def metadata_standards
    @metadata_standards ||= MetadataStandard.all.sort_by(&:name)
  end

  def entity_metadata_standards
    @entity_metadata_standards ||= find_and_update_association(:association_name => 'entity_metadata_standards')
  end

  def metadata_standards_options_for_select
      @metadata_standards_options_for_select =  metadata_standards.collect{|ms| [ ms.description, ms.id ] }
  end

  def vocabularies
    @vocabularies ||= Vocabulary.all
  end

  def clean_params
    #remove_duplicate_nested_attributes_by 'metadata_standard_id', :from => 'entity_metadata_standards_attributes'
  end

end

