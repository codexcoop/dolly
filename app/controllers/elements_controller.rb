class ElementsController < ApplicationController
  before_filter :require_user

  before_filter do |controller|
    #controller.element   # NO! it makes crash all actions, because is adds a
                          # new empty property to the entity.properties
    controller.require_role('admin')
  end

  def index
    @elements = metadata_standard.elements.find(:all, :include => [:metadata_standard, :entity, :vocabulary, :property_elements]).sort_by{|el| el.metadata_standard.description.to_s + el.entity.name.to_s + el.section.to_s + el.name.to_s}

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @elements }
    end
  end

  def show
    @element = metadata_standard.elements.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @element }
    end
  end

  def new
    @element = metadata_standard.elements.build

    vocabularies
    entities

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @element }
    end
  end

  def edit
    @element = metadata_standard.elements.find(params[:id])

    vocabularies
    entities
  end

  def create
    @element = metadata_standard.elements.build(params[:element])

    vocabularies
    entities

    respond_to do |format|
      if @element.save
        flash[:notice] = 'Element was successfully created.'
        format.html { redirect_to metadata_standard_element_url(@metadata_standard, @element) }
        format.xml  { render :xml => @element, :status => :created, :location => @element }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @element.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @element = metadata_standard.elements.find(params[:id])
    @element.attributes = params[:element]

    vocabularies
    entities

    respond_to do |format|
      if @element.update_attributes(params[:element])
        flash[:notice] = 'Element was successfully updated.'
        format.html { redirect_to metadata_standard_element_url(@metadata_standard, @element) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @element.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @element = metadata_standard.elements.find(params[:id])
    @element.destroy

    respond_to do |format|
      flash[:notice] = "Element successfully deleted"
      format.html { redirect_to metadata_standard_elements_url(@metadata_standard) }
      format.xml  { head :ok }
    end
  end

  private

  def metadata_standard
    @metadata_standard ||= MetadataStandard.find(params[:metadata_standard_id])
  end

  def vocabularies
    @vocabularies ||= Vocabulary.all.sort_by(&:name)
  end

  def entities
    @entities ||= Entity.all.sort_by(&:name)
  end

end

