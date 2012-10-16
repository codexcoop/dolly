class DigitalObjectsController < ApplicationController

  include Nestable
  include CustomSqlConditions

  before_filter :require_user
  before_filter :clean_params

  before_filter :only => [:show, :index, :download] do |controller|
    controller.digital_object
    controller.require_role('end_user')
  end

  before_filter :except => [:show, :index, :download,
                            :bookreader, :bookreader_data] do |controller|
    controller.digital_object
    controller.require_role('editor')
  end

  def digital_object
    @digital_object ||= if params[:id].present?
                          DigitalObject.find(params[:id])
                        elsif params[:digital_collection_id].present?
                          DigitalObject.new(:digital_collection_id => params[:digital_collection_id])
                        elsif params[:original_object_id].present?
                          DigitalObject.new(:original_object_id => params[:original_object_id])
                        else
                          DigitalObject.new
                        end
  end

  def index
    digital_objects
    project
    original_object
    digital_collection
    @count_by_status = DigitalObject.for_user(current_user).count_by_status

    respond_to do |format|
      format.html
      format.xml  { render :xml => @digital_objects }
     end
  end

  def show
    digital_object

    entity_terms_grouped
    memoize_terms_attrs

    respond_to do |format|
      format.html
      format.xml do
        @digital_files = digital_object.digital_files.find(:all)
        @nodes = digital_object.nodes
        @toc = digital_object.toc
      end
    end
  end

  def download
    file_path = File.join( RAILS_ROOT, 'public', 'digital_files', digital_object.institution_id.to_s, digital_object.id.to_s, 'pdf', digital_object.digital_files.first.derivative_filename )

    if File.exist?(file_path) and File.file?(file_path)
      send_file(file_path)
    else
      redirect_to :action => "index"
    end
  rescue
    redirect_to :action => "index"
  end

  def restore_positions
    @digital_object = DigitalObject.find(params[:id])

    respond_to do |format|
      if @digital_object.restore_positions
        flash[:notice] = t(:position_successfully_restored, :scope => default_i18n_controllers_scope)
        format.html { redirect_to digital_object_digital_files_url(@digital_object) }
        format.xml  { render :xml => @digital_object }
      else
        flash[:notice] = t(:error_in_restoring_positions, :scope => default_i18n_controllers_scope)
        format.html { redirect_to digital_object_digital_files_url(@digital_object) }
        format.xml  { render :xml => @digital_object, :status => :unprocessable_entity }
      end
    end
  end

  def new
    digital_object

    institution
    #original_objects
    top_level_original_objects
    stand_alone_original_objects
    projects
    digital_collections

    entity_terms_grouped
    terms

    respond_to do |format|
      format.html
      format.xml  { render :xml => digital_object }
    end
  end

  def edit
    digital_object

    institution
    top_level_original_objects
    stand_alone_original_objects
    original_object
    projects
    digital_collections
    digital_collection

    entity_terms_grouped
    terms
    memoize_terms_attrs
  end

  def create
    clean_params

    digital_object.attributes = params[:digital_object]
    digital_object.user_id = current_user.id
    digital_object.institution_id = current_user.institution_id

    institution
    original_objects
    top_level_original_objects
    stand_alone_original_objects
    original_object
    projects
    digital_collections
    digital_collection

    trigger_params "add_associated_models", "select_institution", "select_project"

    manage_form # where methods "entity_terms_grouped", "terms" "memoize_terms_attrs" are called
  end

  def update
    clean_params

    digital_object.user_id = current_user.id unless digital_object.user_id? and current_user >= admin

    institution
    original_objects
    top_level_original_objects
    stand_alone_original_objects
    original_object
    projects
    digital_collections
    digital_collection

    digital_object.attributes = params[:digital_object]
    trigger_params "add_associated_models", "select_institution", "select_project"

    manage_form
  end

  def toc_index
    @toc = digital_object.toc
    @digital_files =  digital_object.digital_files.find(
                        :all,
                        :select => "id, digital_object_id, position, original_filename, derivative_filename, width_small, height_small",
                        :include => [ :nodes ]
                      )
  end

  def browse
    @toc = digital_object.toc
    @digital_file = digital_object.digital_files.first
  end

############################
# NOTE: method needed only if horizontal TOC is used
############################
  def bookreader_record
    #openlibrary.org response example:
    #
    #jsonp1292581548141([{
    #  "identifiers": {},
    #  "table_of_contents": [
    #    { "title": "Editor's Introduction", "label": "", "pagenum": "5", "level": 0 },
    #    { "title": "Glossary", "label": "", "pagenum": "531", "level": 0 },
    #    { "title": "Index", "label": "", "pagenum": "541", "level": 0 }
    #  ],
    #  "series": ["The Harvard classics -- v. 11."],
    #  "covers": [6049046],
    #  "latest_revision": 14,
    #  "ocaid": "originofspecies00darwuoft",
    #  "source_records": ["marc:CollingswoodLibraryMarcDump10-27-2008/Collingswood.out:50007058:760", "ia:originofspecies00darwuoft"],
    #  "title": "The Origin of Species",
    #  "languages": [{ "key": "/languages/eng" }],
    #  "subjects": ["Evolution", "Natural selection"],
    #  "publish_country": "nyu",
    #  "by_statement": "Charles Darwin; with introductions and notes.",
    #  "type": { "key": "/type/edition" },
    #  "revision": 14,
    #  "publishers": ["Collier"],
    #  "last_modified": { "type": "/type/datetime", "value": "2010-12-10T09:16:19.192237" },
    #  "key": "/books/OL23264120M",
    #  "authors": [{ "key": "/authors/OL35839A" }],
    #  "publish_places": ["New York"],
    #  "pagination": "552p. :",
    #  "classifications": {},
    #  "created": { "type": "/type/datetime", "value": "2009-05-29T18:32:55.340290" },
    #  "notes": "52799",
    #  "number_of_pages": 552,
    #  "publish_date": "1909",
    #  "works": [{
    #    "key": "/works/OL515051W"
    #  }]
    #}]);

    table_of_contents_nodes = digital_object.toc.children.find(:all, :include => [:digital_file]).map do |node|
      {
        :title   => node.description,
        :label   => "",
        :pagenum => node.digital_file.position.to_s,
        :level   => 0
      }
    end

    data = {
      :table_of_contents => table_of_contents_nodes
    }

    respond_to do |format|
      format.json { render :json => data }
    end
  end

  def bookreader_data
    digital_files = digital_object.digital_files.find(
                      :all,
                      :select => "id, position, derivative_filename, width_large, height_large"
                      # :conditions => "derivative_filename IS NOT NULL AND large_technical_metadata IS NOT NULL"
                    )

    data = {
      :heights      => digital_files.map{|file| file.height_large },
      :widths       => digital_files.map{|file| file.width_large },
      :base_path    => digital_object.digital_files_absolute_path(:variant => 'L'),
      :leaf_map     => digital_files.map(&:derivative_filename),
      :page_numbers => digital_files.map{|file| file.position.to_s},
      :page_ids     => digital_files.map(&:id),
      # TODO: dynamic composite title
      # :book_title   => "Il giornale di Voghera - " + digital_object.title,
      :book_title   => digital_object.title,
      :book_url     => digital_object_url(digital_object)
    }

    respond_to do |format|
      format.json { render :json => data }
    end
  end

  def bookreader
    @digital_files = digital_object.digital_files

    render :layout => 'bookreader'
  end

  # TODO: this should be in digital_files_controller, requires some adjustments in browse.js
  def digital_file_path
    digital_object = DigitalObject.find(params[:id])

    if params[:digital_file_id].present?
      digital_file = DigitalFile.find(params[:digital_file_id])
    else
      digital_file = digital_object.digital_files.first
    end

    @hash_for_json_response = {
      :current_digital_file_absolute_path => digital_file.absolute_path(:variant => params[:variant],
                                                                        :institution_id => digital_object.institution_id),
      :current_digital_file_id => digital_file.id,
      :previous_digital_file_id => digital_file.previous_digital_file.try(:id),
      :next_digital_file_id => digital_file.next_digital_file.try(:id)
    }

    respond_to do |format|
      format.json  { render :json => @hash_for_json_response }
    end

  end

  # ActiveRecord::Base.include_root_in_json = false
  # TODO
  # @nodes = Node.find_all_by_digital_object_id(params[:id], :select => "description AS data")
  # Riferimenti:
  # http://api.rubyonrails.org/classes/ActiveRecord/Serialization.html#M001364
  # http://blog.codefront.net/2007/10/10/new-on-edge-rails-json-serialization-of-activerecord-objects-reaches-maturity/
  # Usare children method di acts_as_tree?
  #          @nodes = {
  #            :data => "Root node - 1",
  #            :attr => { :id => "node-1" },
  #            :children => [
  #                {
  #                  :data => "Child node - 2",
  #                  :attr => { :id => "node-2" }
  #                },
  #                {
  #                  :data => "Child node - 3",
  #                  :attr => { :id => "node-3" },
  #                  :children => [
  #                    {
  #                    :data => "Child node - 5",
  #                    :attr => { :id => "node-5" }
  #                    },
  #                    {
  #                    :data => "Child node - 6",
  #                    :attr => { :id => "node-6" }
  #                    }
  #                  ]
  #                },
  #                {
  #                  :data => "Child node - 4",
  #                  :attr => { :id => "node-4" }
  #                }
  #            ]
  #          }

  def destroy
    digital_object.destroy
    flash[:notice] = t :deleted_successfully, :scope => default_i18n_controllers_scope

    respond_to do |format|
      format.html { redirect_to(digital_objects_url) }
      format.xml  { head :ok }
    end
  end

  def destroy_with_assets
    digital_object
    digital_files
  end

  def perform_destroy_with_assets
    FileUtils.rm_r(digital_object.assets_dir, :force => true) if digital_object.assets_dir
    digital_object.digital_files.each(&:destroy)
    digital_object.nodes.each(&:destroy)
    digital_object.update_attributes(:digital_files_count => 0)
    digital_object.destroy

    flash[:notice] = t :assets_deleted_successfully, :scope => default_i18n_controllers_scope

    respond_to do |format|
      format.html { redirect_to(digital_objects_url) }
      format.xml  { head :ok }
    end
  end

  def toggle_completed
    @digital_object = DigitalObject.find(params[:id])
    @digital_object.toggle!(:completed)

    redirect_to(request.referrer, :notice => t(:updated_successfully, :scope => default_i18n_controllers_scope))
  end

  private

    def institutions
      @institutions ||= if current_user.permission_level >= admin.permission_level
                          Institution.all
                        elsif current_user.permission_level >= editor.permission_level
                          [current_user.institution]
                        else
                          nil
                        end
    end

    def original_object
      @original_object ||=  if digital_object
                              digital_object.original_object
                            elsif not params[:digital_object].blank? and not params[:digital_object][:original_object_id].blank?
                              OriginalObject.find(params[:digital_object][:original_object_id])
                            else
                              nil
                            end
    end

    def digital_collection
      @digital_collection ||= if not params[:digital_object].blank? and not params[:digital_object][:digital_collection_id].blank?
                                DigitalCollection.find(params[:digital_object][:digital_collection_id])
                              elsif digital_object
                                digital_object.digital_collection
                              else
                                nil
                              end
    end

    def project
      @project ||=  if params[:project_id]
                      Project.find(params[:project_id])
                    elsif digital_collection
                      digital_collection.project
                    else
                      nil
                    end
    end

    def institution
      @institution ||=  if params[:institution_id]
                          Institution.find(params[:institution_id])
                        elsif project
                          project.institution
                        else
                          institution = current_user.institution
                        end
    end

    def projects
      @projects ||= if institution
                      institution.projects.sort_by(&:title)
                    else
                      []
                    end
    end

    def original_objects
      @original_objects ||= if institution
                              institution.original_objects.sort_by(&:title)
                            else
                              []
                            end
    end

    def top_level_original_objects
      @top_level_original_objects ||= if institution
                                        institution.original_objects.top_level
                                      else
                                        []
                                      end
    end

    def stand_alone_original_objects
      @stand_alone_original_objects ||= if institution
                                        institution.original_objects.stand_alone
                                      else
                                        []
                                      end
    end

    def digital_collections
      @digital_collections  =   if current_user >= admin
                                  DigitalCollection.all.sort_by(&:title_with_project)
                                else
                                  current_user.
                                  institution.
                                  projects.
                                  map{|prj| prj.digital_collections}.
                                  flatten.
                                  sort_by(&:title_with_project)
                                end
    end

    def digital_files
      @digital_files ||= digital_object.digital_files.find(:all)
    end

    def clean_params
      super
      params[:institution_id] = current_user.institution_id unless (current_user <= end_user or current_user >= admin)
      params.delete_if{|k,v| v.blank? } if params
      params[:digital_object].delete_if{|k,v| k == 'identifier'} if params[:digital_object]
    end

    def digital_objects
      clean_params
      search_conditions = search_conditions_for(OriginalObject, :title, :main_related_title, :param_key => :title)
      @digital_objects ||=  if current_user <= end_user || current_user >= admin
                              DigitalObject.
                                custom_search(params, sort_string(params[:sort], "ordering_title"), search_conditions).
                                status(params[:status]).
                                paginate(:page => params[:page], :per_page => DigitalObject.per_page)
                            else
                              DigitalObject.
                                custom_search(current_user, params, sort_string(params[:sort], "ordering_title"), search_conditions).
                                status(params[:status]).
                                paginate(:page => params[:page], :per_page => DigitalObject.per_page)
                            end
    end

end

