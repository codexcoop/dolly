# this module is thought to be plugged in the application controller

# TODO: consider CanCan again, version >= 1.4
module AuthorizationsControl
  def roles
    @non_filtered_roles = Role.all
  end

  def admin # permission_level 3
    @non_filtered_roles.select{|role|role.name == 'admin'}.first
  end

  def institution_admin # permission_level 2
    @non_filtered_roles.select{|role|role.name == 'institution_admin'}.first
  end

  def editor # permission_level 1
    @non_filtered_roles.select{|role|role.name == 'editor'}.first
  end

  def end_user # permission_level 0
    @non_filtered_roles.select{|role|role.name == 'end_user'}.first
  end

  def is_root?
    current_user and current_user == admin
  end

  def is_admin?
    current_user and current_user >= institution_admin
  end

  def permission_level_for_role(role_name)
    @non_filtered_roles.select{|role|role.name == role_name}.first.permission_level
  end

  # TODO: define a custom Class for access denial, temporarily CanCan::AccessDenied is used in its place
  def require_role(target_role)
    unless current_user and is_owner? and current_user.permission_level >= permission_level_for_role(target_role)
      raise CanCan::AccessDenied
    end
  rescue CanCan::AccessDenied
    flash[:notice] = t :access_denied, :scope => [:application]
    redirect_to dashboard_url
    return false
  end

  def is_owner?(options={})
    auth_controller = options[:controller_name] || controller_name
    auth_action = options[:authorizable_action] || action_name
    auth_object = options[:authorizable_object] || instance_variable_get(:"@#{controller_name.tableize.singularize}")

    if current_user.nil?
      return false
    elsif current_user and current_user >= admin and (auth_controller != 'users') and (auth_controller != 'institutions')
      return true
    else
      case auth_controller
        when 'institutions'
          (%W(index).include? auth_action and (current_user >= admin or current_user == end_user)) or
          (%W(show).include? auth_action and ((current_user.institution_id == auth_object.id and current_user >= institution_admin) or current_user == end_user)) or
          (%W(edit update).include? auth_action and current_user.institution_id == auth_object.id and current_user >= institution_admin) or
          (auth_action == 'destroy' and current_user >= admin and auth_object.id != 1) or
          (auth_action != 'destroy' and current_user >= admin)
        when 'original_objects'
          (%w(index).include?(auth_action) and current_user >= end_user) or
          (%w(show).include?(auth_action) and (current_user.institution_id == auth_object.institution_id or current_user == end_user)) or
          (%w(new create).include?(auth_action) and current_user >= editor) or
          (%w(edit update destroy).include?(auth_action) and current_user >= editor and current_user.institution_id == auth_object.institution_id)
        when 'projects'
          (%w(index).include?(auth_action) and current_user >= end_user) or
          (%w(show).include?(auth_action) and (current_user.institution_id == auth_object.institution_id or current_user == end_user)) or
          (%w(new create).include?(auth_action) and current_user >= institution_admin) or
          (%w(edit update destroy).include?(auth_action) and current_user.institution_id == auth_object.institution_id and current_user >= institution_admin )
        when 'digital_collections'
          (%w(index).include?(auth_action) and current_user >= end_user) or
          (%w(show).include?(auth_action) and (current_user.institution_id == auth_object.institution_id or current_user == end_user))  or
          (%w(new create ).include?(auth_action) and current_user >= institution_admin) or
          (%w(edit update destroy).include?(auth_action) and
                      current_user >= institution_admin and
                      current_user.institution_id == auth_object.institution_id)
        when 'digital_objects'
          (%w(index).include?(auth_action) and current_user >= end_user) or
          (%w(toc_nodes                     update_digital_object_toc
              toc_index                     browse              bookreader
              bookreader_data               bookreader_record   digital_file_path
              perform_destroy_with_assets   restore_positions   destroy_with_assets).
              include?(auth_action) and
              current_user.institution_id.to_s == auth_object.institution_id.to_s and
              current_user >= editor) or
          (%w(show download bookreader bookreader_data).
              include?(auth_action) and (current_user.institution_id.to_s == auth_object.institution_id.to_s or current_user == end_user)) or
          (%w(new create).include?(auth_action) and
                                  current_user >= editor) or
          (%w(destroy toggle_completed).include?(auth_action) and
                                  current_user >= institution_admin and
                                  current_user.institution_id.to_s == auth_object.institution_id.to_s) or
          (%w(edit update).include?(auth_action) and
                          current_user >= editor and
                          current_user.institution_id.to_s == auth_object.institution_id.to_s)
        when 'digital_files'
          (%w(index).include?(auth_action) and current_user >= end_user) or
          (%w(move).include?(auth_action) and (current_user.institution_id == auth_object.institution_id and current_user >= editor)) or
          (%w(destroy).include?(auth_action) and
                                  current_user >= institution_admin and
                                  current_user.institution_id == auth_object.institution_id)
        when 'users'
          (%w(index).include?(auth_action) and current_user >= institution_admin) or
          (%w(edit update).include?(auth_action) and
              (current_user.id == auth_object.id or
              (current_user.institution_id == auth_object.institution_id and current_user >= auth_object) or
              current_user >= admin) ) or
          (%w(new create).include?(auth_action) and current_user >= institution_admin) or
          (%w(destroy).include?(auth_action) and current_user >= admin and auth_object.id != current_user.id and auth_object.id.to_s!='1')
        else
          return false # toggle this for easier debug
      end # case
    end # if elsif else...
  end # def is_owner?

end

