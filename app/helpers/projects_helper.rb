module ProjectsHelper

  def digital_collections_link_text_for_project(project)
    t(:digital_collection, :count =>  project.digital_collections.size, :scope => [:activerecord, :models]).downcase
  end

  def link_to_digital_collections_for_project(project)
    if project.digital_collections.size > 0
      link_to digital_collections_link_text_for_project(project), project_digital_collections_path(project)
    end
  end

end

