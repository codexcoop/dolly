class PropertiesController < ApplicationController

  include Nestable

  before_filter :require_user
  before_filter :clean_params

  before_filter do |controller|
    #controller.property  # NO! it makes crash all actions, because is adds a
                          # new empty property to the entity.properties
    controller.require_role('admin')
  end

  def index
    @properties = entity.properties.find( :all, :include => [ :vocabulary, :entity, {:elements => [:metadata_standard, :vocabulary]}], :order => 'properties.position, properties.name')

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @properties }
    end
  end

  def show
    @property = entity.properties.find(params[:id])

    vocabularies
    metadata_standards
    property_elements

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @property }
    end
  end

  def new
    @property = entity.properties.build

    property_elements
    vocabularies
    metadata_standards
    entity

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @property }
    end
  end

  def edit
    @property = Property.find(params[:id])

    property_elements
    vocabularies
    metadata_standards
    entity
  end

  def create
    clean_params

    @property = entity.properties.build(params[:property])

    property_elements
    vocabularies
    metadata_standards
    entity

    respond_to do |format|
      if params['add_metadata_standard_element'].present? or params['update_form'].present?
        format.html { render :action => 'new'}
      elsif @property.save
        flash[:notice] = 'Property successfully created.'
        format.html { redirect_to entity_property_url(entity, @property) }
        format.xml  { render :xml => @property, :status => :created, :location => @property }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @property.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    clean_params

    @property = entity.properties.find(params[:id])
    @property.attributes = params[:property]

    property_elements
    vocabularies
    metadata_standards
    entity

    respond_to do |format|
      if params['add_metadata_standard_element'].present? or params['update_form'].present?
        format.html { render :action => 'edit'}
      elsif @property.save
        flash[:notice] = 'Property successfully updated.'
        format.html { redirect_to entity_property_url(entity, @property) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @property.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @property = entity.properties.find(params[:id])
    @property.destroy

    flash[:notice] = "Property successfully deleted"

    respond_to do |format|
      format.html { redirect_to entity_properties_url(entity) }
      format.xml  { head :ok }
    end
  end

  private

  def entity
    @entity ||= Entity.find(params[:entity_id])
  end

  def entities
    @entities ||= Entity.all.sort_by(&:name)
  end

  def property_elements
    @property_elements ||= find_and_update_association(:association_name => 'property_elements')
  end

  def all_metadata_standards
    @all_metadata_standards ||= MetadataStandard.all.sort_by(&:name)
  end

  def metadata_standards
    @metadata_standards ||= entity.metadata_standards.find(:all, :include => :elements)
  end

  def vocabularies
    @vocabularies ||= Vocabulary.all.sort_by(&:name)
  end

  def clean_params
    # remove_duplicate_nested_attributes_by 'element_id', :from => 'property_elements_attributes'
  end

end

