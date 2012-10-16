require 'ingestable/constants'

module Ingestable
  module Paths

    #include Ingestable::Constants

    DIGITAL_FILES_DIR   = File.join(RAILS_ROOT, 'public', 'digital_files')

    attr_accessor :dir_entry

    def digital_object_pdf_path
      @digital_object_pdf_path ||= File.join DIGITAL_FILES_DIR, self.institution_id.to_s, self.id.to_s, 'pdf'

      unless File.exist?(@digital_object_pdf_path) and File.directory?(@digital_object_pdf_path)
        FileUtils.mkpath(@digital_object_pdf_path)
      end
      puts_and_log  "Paths for imported images correctly set" +
                    "\n--------------------------------------------------------\n"
      @digital_object_pdf_path
    rescue Exception => exception
      puts_and_log  "The required path cannot be set. Please try again. #{exception.inspect}" +
                    "\n--------------------------------------------------------\n"
      nil
    end

    # TODO: rinominare in derivatives_paths
    def digital_object_paths
      paths = []
      paths << digital_object_path           = File.join(DIGITAL_FILES_DIR, self.institution_id.to_s, self.id.to_s)
      #paths << digital_object_path_original  = File.join(digital_object_path, 'O')
      paths << digital_object_path_large     = File.join(digital_object_path, 'L')
      paths << digital_object_path_medium    = File.join(digital_object_path, 'M')
      paths << digital_object_path_small     = File.join(digital_object_path, 'S')
      paths.each do |required_path|
        unless File.exist? required_path and File.directory? required_path
          FileUtils.mkpath required_path
        end
      end
                    "\n--------------------------------------------------------\n"
      # { :main     => digital_object_path,
      #   :original => digital_object_path_original,
      #   :large    => digital_object_path_large,
      #   :medium   => digital_object_path_medium,
      #   :small    => digital_object_path_small }
      { :main     => digital_object_path,
        #:original => digital_object_path_original,
        :large    => digital_object_path_large,
        :medium   => digital_object_path_medium,
        :small    => digital_object_path_small }
    rescue Exception => exception
      puts_and_log  "The required path/s cannot be set. Please try again. #{exception.inspect}" +
                    "\n--------------------------------------------------------\n"
      {}
    end

  end
end

