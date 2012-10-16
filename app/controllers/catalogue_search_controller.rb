class CatalogueSearchController < ApplicationController

  before_filter :require_user
  before_filter :clean_params
  before_filter :params_all_valid?, :only => [:search_z3950]

  def new
    @original_object = OriginalObject.new
    params[:search] ||= {}
  end

  def search_z3950
    begin
      @results = Z3950Search.perform(params) # => see lib/z3950_search.rb
    rescue Exception => e
      flash[:alert] = t :catalogue_connection_error, :scope => default_i18n_controllers_scope
    end

    respond_to do |format|
      if @results
        format.html { render "results" }
      else
        format.html { render :action => 'new' }
      end
    end
  end

  private

  def params_all_valid?
    flash[:alert] = nil
    @params_all_valid = true

    if params[:search].none? || params[:search].all?{|k,v| v.blank?}
      @params_all_valid = false
      add_to_alert t('.at_least_one_parameter', :scope => default_i18n_controllers_scope)
    else
      params[:search].each_pair do |key,value|
        self.send("validate_#{key}".to_sym, value) if private_methods.grep(Regexp.new("validate_#{key}")).any?
      end
    end

    unless @params_all_valid
      respond_to do |format|
        format.html { render :action => 'new' }
      end
    end
  end

  def validate_date_publication(value)
    if value.to_i < 0 || value.to_s =~ /[^\d+]/
      @params_all_valid = false
      @date_publication_error = true
      add_to_alert t('.generic_date_error', :scope => default_i18n_controllers_scope)
    end
  end

  def clean_params
    params[:search] = params[:search].each_pair{|k,v| params[:search][k] = v.strip.squeeze("\s+") } if params[:search].present?
  end

end

