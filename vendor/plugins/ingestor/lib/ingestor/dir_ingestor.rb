module Ingestor

  class DirIngestor
    attr_reader   :digital_object_id
    attr_accessor :source, :destination, :file_ingestor_class, :logger
    attr_writer   :original_filepaths

    # required params
    # :source, :destination, :digital_object_id, :file_ingestor_class
    def initialize(opts={})
      opts.each do |option, value|
        send "#{option}=".to_sym, value
      end

      required_params = [:source, :destination, :digital_object_id, :file_ingestor_class]
      unless required_params.map{|param| self.send(param)}.all?
        raise ArgumentError, "Required options: #{required_params.map(&:inspect).join(', ')}"
      end
    end

    # Occam
    def digital_object_id=(digital_object)
      @digital_object_id = digital_object.is_a?(Fixnum) ? digital_object : digital_object.id
    end

    def original_filepaths
      @original_filepaths ||= Dir[File.join(source, '*')].sort
    end

    def each_file_ingestor
      original_filepaths.each_with_index do |original_filepath, index|
        file_ingestor = file_ingestor_class.new(
          :original_filepath  => original_filepath,
          :derivative_dirpath => destination,
          :digital_object_id  => digital_object_id
        )

        if file_ingestor.digital_file.nil?
          logger.debug %Q{No digital_file for "#{file_ingestor.original_filepath}"} if logger
          next
        elsif file_ingestor.raw.nil?
          logger.debug %Q{Could not open "#{file_ingestor.original_filepath}"} if logger
          next
        else
          yield file_ingestor, index
        end
      end
    end

  end

end

