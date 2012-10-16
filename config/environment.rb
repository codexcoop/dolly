# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.14' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

customizations_path = Dir[File.join(RAILS_ROOT, "lib", "*.rb")].reject do |path|
  path =~ /.*\/tasks.*/
end

Dir.glob(customizations_path).each do |filepath|
  require filepath.gsub(/.rb/,'')
end

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.autoload_paths +=  Dir["#{RAILS_ROOT}/lib/**/"]

  # Specify gems that this application depends on and have them installed with rake gems:install
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "sqlite3-ruby", :lib => "sqlite3"
  # config.gem "aws-s3", :lib => "aws/s3"

  # Common
  config.gem "i18n",          :version => "0.6.1"
  config.gem "pg",            :version => "0.14.1"
  config.gem "authlogic",     :version => "2.1.6"
  config.gem "cancan",        :version => "1.6.7"

  config.gem "acts_as_list",  :version => "0.1.2"
  config.gem "acts_as_tree",  :version => "0.1.1"
  config.gem "ancestry",      :version => "1.2.4"
  config.gem "will_paginate", :version => "2.3.16"
  config.gem "RedCloth",      :version => "4.2.9"
  config.gem "paperclip",     :version => "2.4.5"

  # Dolly specific
  config.gem "zoom",          :version => "0.4.1" # => requires ruby 1.8.7 (not working with 1.9)
  config.gem "exifr",         :version => "~> 1.1.1"
  config.gem "pdf-reader",    :version => "~> 0.10.1"

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]
  # TODO: move ingestor in lib
  config.plugins = [ :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'Rome'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  config.i18n.load_path += Dir[File.join(RAILS_ROOT, 'config', 'locales', '**', '*.{rb,yml}')]
  config.i18n.default_locale = :it

end

