module UsersHelper

  def institution_select_for_user(form_builder, user, institutions, css_class)
    form_builder.collection_select(
      :institution_id,
      institutions,
      :id,
      :name,
      {:selected => selected_institution_id_for_user(user)},
      {:disabled => current_user < admin, :class => css_class }
    )
  end

  def selected_institution_id_for_user(user)
    if (current_user < admin || user.new_record?) && user.institution_id.blank?
      current_user.institution_id
    else
      user.institution_id
    end
  end

  def role_select_for_user(form_builder, user, roles, css_class)
    form_builder.collection_select(
      :role_id,
      roles,
      :id,
      :name,
      {:prompt => t(:please_select, :scope => :application)},
      {:disabled => (roles.size <= 1 || (is_root? && user == admin)), :class => css_class}
    )
  end

end

