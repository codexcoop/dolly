module Ingestor

  module DirIngestSupport

    def each_file_ingestor(opts={})
      source = opts[:source] || digital_object_paths[:large]

      digital_files.each_with_index do |digital_file, index|
        file_ingestor = opts[:file_ingestor_class].new(
          :original_filepath  => File.join(source, digital_file.derivative_filename),
          :derivative_dirpath => opts[:destination],
          :digital_object_id  => id,
          :digital_file       => digital_file
        )

        if file_ingestor.raw.nil?
          opts[:logger].debug %Q{Could not open "#{file_ingestor.original_filepath}"} if opts[:logger]
          next
        else
          yield file_ingestor, index
        end
      end
    end

  end

end

