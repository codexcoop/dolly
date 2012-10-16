# TODO: should be in an "admin" namespace

class VocabulariesController < ApplicationController
  before_filter :require_user

  before_filter do |controller|
    controller.require_role('admin')
  end

  def index
    if params[:metadata_standard_id].present?
      @metadata_standard = MetadataStandard.find(params[:metadata_standard_id])
      @vocabularies = @metadata_standard.vocabularies
    else
      @vocabularies = Vocabulary.all(:order => 'name')
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @vocabularies }
    end
  end

  def show
    @vocabulary = Vocabulary.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @vocabulary }
    end
  end

  def new
    @vocabulary = Vocabulary.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @vocabulary }
    end
  end

  def edit
    @vocabulary = Vocabulary.find(params[:id])
    @updating = true
  end

  def create
    @vocabulary = Vocabulary.new(params[:vocabulary])

    respond_to do |format|
      if @vocabulary.save
        flash[:notice] = t :created_successfully, :scope => default_i18n_controllers_scope
        format.html { redirect_to(@vocabulary) }
        format.xml  { render :xml => @vocabulary, :status => :created, :location => @vocabulary }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @vocabulary.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @vocabulary = Vocabulary.find(params[:id])

    respond_to do |format|
      if @vocabulary.update_attributes(params[:vocabulary])
        flash[:notice] = t :updated_successfully, :scope => default_i18n_controllers_scope
        format.html { redirect_to(@vocabulary) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @vocabulary.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @vocabulary = Vocabulary.find(params[:id])
    @vocabulary.destroy
    flash[:notice] = t :deleted_successfully, :scope => default_i18n_controllers_scope

    respond_to do |format|
      format.html { redirect_to(vocabularies_url) }
      format.xml  { head :ok }
    end
  end
end

