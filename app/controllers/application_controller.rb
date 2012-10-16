
require 'RedCloth'

class ApplicationController < ActionController::Base
  include AuthorizationsControl
  include UserSessionsControl

  helper :all
  helper_method :current_user_session,
                :current_user,
                :is_root?,
                :is_admin?,
                :is_owner?,
                :admin,
                :institution_admin,
                :editor,
                :end_user,
                :locale_language_id

  protect_from_forgery

  def initialize
    super
    roles
  end

  rescue_from ActiveRecord::StatementInvalid, :with => :restrict_if_dependent_rescue

  def restrict_if_dependent_rescue(exception)
    session[:return_to] = request.request_uri
    redirect_to (url_for(:action => 'index') || dashboard_url)
    # TODO: create an i18n message for the restrict_if_dependent exception
    flash[:notice] = exception.message
    session[:return_to] = nil
  end

  def current_model
    # DigitalCollection for example
    @current_model ||= self.class.name.tableize.split('_').values_at(0...-1).join('_').tableize.classify.constantize
  end

  private

  def add_to_alert(message)
    if flash[:alert] then flash[:alert] += "\n<br />#{message}" else flash[:alert] = message end
  end

  def current_object_name
    # "digital_collection"
    controller_name.singularize
  end

  def current_object_params
    # params[:digital_collection]
    params[current_object_name.to_sym]
  end

  def current_object
    # @digital_collection for example
    if instance_variable_get(:"@#{current_object_name}")
      instance_variable_get(:"@#{current_object_name}")
    elsif respond_to? current_object_name.to_sym
      self.send(current_object_name.to_sym)
    end
  end

  def default_i18n_controllers_scope
    [:controllers, controller_name.to_sym]
  end

  def locale_language_id
    ApplicationLanguage.find_by_code(I18n.locale.to_s).id
  end

  # first argument: model class
  # other arguments: column names (at least one)
  # last argument: mandatory option hash with key ":param_key"
  def search_conditions_for(*args)
    opts        = args.pop
    table_name  = args.shift.table_name
    attr_names  = args
    if params[opts[:param_key].to_sym].present?
      fragments = params[opts[:param_key].to_sym].squish.split("\s").map{|fragment| "%#{fragment}%"}
      interpolated_conditions = attr_names.map do |attr_name|
        interpolate_conditions(:and, :ilike, {"#{table_name}.#{attr_name}" => fragments})
      end
      mix_interpolated_conditions(:or, *interpolated_conditions)
      # => see lib/custom_sql_conditions.rb
    else
      {}
    end
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end

  def sort_string(sort_param, default_sort)
    sort_column = sort_param.blank? ? default_sort : sort_param
    "#{sort_column} #{sort_direction}"
  end

  # Options: if @fond has_many :creators through :rel_creator_fonds...
  # - :for is the current_object, for example @fond (optional)
  # - :related the target association, ex. :creators (required)
  # - :through is the linking association, ex. :rel_creator_fonds (required)
  # - :available is the available target size, ex. @available_creators
  #   optional, if not provide will be automatically computed, as Creator.count('id')
  # - :suggested is a proc that defines the collection of possible related objects;
  #   this colleciton will be presented for rapid choice (optional);
  #   the block (and then the query), will be executed only if the available target size
  #   is greater than the threshold value;
  #   example: Proc.new{ Creator.all(:select => "id, name", :order => "name") }
  # - :threshold is the maximum size that will be allowed for the collection of
  #   suggested elements, (optional, default 5)
  # - :if is an additional condition (intended as boolean value) that will be checked together with the threshold
  #
  # Given the options, the method will then define the following instance variables
  # - @fond
  # - @rel_creator_fonds
  # - @available_creators
  # - @creators_threshold
  # - @suggested_creators (only if a proc is given as :suggested, and the conditions are met)
  def relation_collections(opts={})
    current_object  = opts[:for]       # => @fond
    related         = opts[:related]   # => :creators
    through         = opts[:through]   # => :rel_creator_fonds
    suggested       = opts[:suggested] # => a block containing a query
    threshold       = opts[:threshold] || 5
    available       = opts.key?(:available) ? opts[:available] : false
    conditions      = opts.key?(:if) ? opts[:if] : true

    # @fond
    current_object ||= instance_variable_get("@#{controller_name.classify.underscore}".to_sym)
    # @rel_creator_fonds = @fond.sorted_rel_creator_fonds
    instance_variable_set("@#{through}".to_sym, current_object.send("sorted_#{through}"))
    # @creators_threshold = 5
    instance_variable_set("@#{related}_threshold", threshold)
    # @available_creators   = Creator.count('id') // fixed, warning: the process is different from other variables
    available = instance_variable_set("@available_#{related}", (available || related.classify.constantize.count('id'))) if available
    # @suggested_creators
    if suggested && conditions # && available <= threshold
      instance_variable_set("@suggested_#{related}", suggested.call)
    end
  end

end

