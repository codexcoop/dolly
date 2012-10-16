ActionController::Routing::Routes.draw do |map|

  map.resources :users

  map.resources :user_sessions

  map.resources :institutions, :has_many => [ :projects,
                                              :digital_collections,
                                              :digital_objects,
                                              :original_objects ]

  map.resources :original_objects,
    :member     =>  {
                      :search_z3950         => :post,
                      :associations         => :get,
                      :create_association   => :put,
                      :destroy_association  => :delete
                    },
    :collection =>  {
                      :initialize_with_unimarc  => :post,
                      :ajax_search => :get
                    },
    :has_many   => :digital_objects

  map.resource  :catalogue_search,
                :controller => 'catalogue_search',
                :only => [:new],
                :collection => {
                  :search_z3950 => :post
                }

  map.resources :projects do |projects|
    projects.resources :digital_collections
    projects.resources :digital_objects, :only => [:index]
  end

  map.resources :digital_files, :only => :toggle_key_image, :member => {:toggle_key_image => :put}

  map.resources :digital_objects,
                :member => {
                            :download                     => :get,
                            :browse                       => :get,
                            :bookreader                   => :get,
                            :bookreader_data              => :get,
                            :bookreader_record            => :get,
                            :digital_file_path            => :get,
                            :toc_index                    => :get,
                            :restore_positions            => :get,
                            :destroy_with_assets          => :get,
                            :perform_destroy_with_assets  => :post,
                            :toggle_completed             => :put },
                :collection => {:process_thumbnails => :get} do |digital_object|
                  # OPTIMIZE: perché nested? per autorizzazione?
                  digital_object.resources :digital_files, :member => {:move => :put},
                                                           :only => [:index, :destroy]
                  digital_object.resources :nodes, :member => { :move => :put,
                                                                :assign => :put,
                                                                :remove_assignment => :put,
                                                                :description_template => :get },
                                                   :except => [:edit, :show]
                end

  map.resources :entities, :has_many => [:properties]

  map.resources :application_languages

  map.resources :terms, :collection => {:list => :get}

  map.resources :vocabularies do |vocabulary|
    vocabulary.resources :terms, :member => { :move => :put }
  end

  map.resources :metadata_standards, :has_many => [:elements, :vocabularies]

  map.resources :digital_collections do |digital_collections|
    digital_collections.resources :digital_objects
    digital_collections.resources :original_objects, :only => [:index]
  end

  map.root :controller => "site"

  map.login 'login', :controller => 'user_sessions', :action => 'new'

  map.logout 'logout', :controller => 'user_sessions', :action => 'destroy'

  map.dashboard 'dashboard', :controller => 'site', :action => 'dashboard'


  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  #  map.connect ':controller/:action/:id'
  #  map.connect ':controller/:action/:id.:format'
end

