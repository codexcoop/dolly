class UsersController < ApplicationController
  before_filter :require_user
  before_filter :define_shared_instance_variables
  before_filter :only => [:edit, :update] do |controller|
    controller.require_role('end_user')
  end
  before_filter :only => [:new, :create, :destroy, :index] do |controller|
    controller.require_role('institution_admin')
  end

  # TODO: convert to presenter pattern
  def define_shared_instance_variables
    sanitize_params_for_role_changes
    sanitize_params_for_institution_changes

    @user = if params[:id]
              User.find(params[:id])
            elsif params[:user]
              User.new(params[:user])
            else
              User.new
            end
    @same_institution_only = true if current_user <= institution_admin

    @roles =  if @user.new_record? or @user.id != current_user.id
                Role.all(:order => "id DESC").select{|role| role.permission_level <= current_user.permission_level and
                                                            role.permission_level != admin.permission_level}
              else
                [@user.role]
              end

    @institutions = Institution.all.select{|institution| is_owner?(:authorizable_object => institution,
                                                                    :authorizable_action => 'edit',
                                                                    :controller_name => 'institutions') or
                                                         institution.id == current_user.institution_id }

  end

  def sanitize_params_for_role_changes
    if params[:user]
      params[:user].delete_if do |key, value|
                                (not value.blank?) and
                                key == 'role_id' and
                                Role.find(value).permission_level > current_user.permission_level
                              end
    end
  end

  def sanitize_params_for_institution_changes
    if params[:user]
      params[:user].delete_if {|key, value| key == 'institution_id' && (current_user < admin)}
    end
  end

  def find_users(additional_conditions={})
    users = User.list.all(:conditions => additional_conditions,
                          :order => "users.institution_id, users.role_id DESC, users.last_name, users.first_name ASC")
  end

  def index
    if current_user >= admin and not params[:institution_id].blank?
        @users = find_users :institution_id => params[:institution_id].to_i
    elsif current_user >= admin
      @users = find_users
    else
      @users = find_users :institution_id => current_user.institution_id
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @users }
     end
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])
    @user.institution_id = current_user.institution_id unless current_user >= admin

    if @user.save
      flash[:notice] = t :created_successfully, :scope => default_i18n_controllers_scope
      redirect_to url_for(:action => 'index')
    else
      render :action => :new
    end
  end

  def show
    @user = User.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @application_language }
    end
  end

  def edit
    @user = User.find(params[:id])
    @updating = true
  end

  def update
    @user = User.find(params[:id])
    @user.attributes = params[:user]
    @user.institution_id = current_user.institution_id unless current_user >= admin

    if @user.save
      flash[:notice] = t :updated_successfully, :scope => default_i18n_controllers_scope
      if is_admin?
        target = users_path
      else
        target = dashboard_path
      end
      redirect_to target
    else
      render :action => :edit
    end
  end

  # TODO: restrict users deletion
  def destroy
    @user = User.find(params[:id])
    @user.destroy
    flash[:notice] = t :deleted_successfully, :scope => default_i18n_controllers_scope

    respond_to do |format|
      format.html { redirect_to url_for(:action => 'index') }
      format.xml  { head :ok }
    end
  end
end
