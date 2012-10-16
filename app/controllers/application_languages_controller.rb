# TODO: should be in an "admin" namespace

class ApplicationLanguagesController < ApplicationController
  before_filter :require_user

  def index
    @application_languages = ApplicationLanguage.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @application_languages }
    end
  end

  def show
    @application_language = ApplicationLanguage.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @application_language }
    end
  end

  def new
    @application_language = ApplicationLanguage.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @application_language }
    end
  end

  def edit
    @application_language = ApplicationLanguage.find(params[:id])
  end

  def create
    @application_language = ApplicationLanguage.new(params[:application_language])

    respond_to do |format|
      if @application_language.save
        flash[:notice] = 'Language was successfully created.'
        format.html { redirect_to(@application_language) }
        format.xml  { render :xml => @application_language, :status => :created, :location => @application_language }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @application_language.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @application_language = ApplicationLanguage.find(params[:id])

    respond_to do |format|
      if @application_language.update_attributes(params[:application_language])
        flash[:notice] = 'Language was successfully updated.'
        format.html { redirect_to(@application_language) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @application_language.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @application_language = ApplicationLanguage.find(params[:id])
    if @application_language.destroy
      flash[:notice] = 'Language successfully removed'
    else
      flash[:notice] = 'Language was not removed'
    end

    respond_to do |format|
      format.html { redirect_to(application_languages_url) }
      format.xml  { head :ok }
    end
  end
end

