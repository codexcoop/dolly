require 'custom_extensions/array'
require 'custom_extensions/hash'
require 'custom_extensions/object'
require 'custom_extensions/string'
require 'custom_extensions/dir'

::Array.class_eval{ include CustomExtensions::Array }
::Hash.class_eval{ include CustomExtensions::Hash }
::Object.class_eval{ include CustomExtensions::Object }
::String.class_eval{ include CustomExtensions::String }
::Dir.extend(CustomExtensions::Dir::ClassMethods)

