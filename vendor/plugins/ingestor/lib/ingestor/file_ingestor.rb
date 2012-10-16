module Ingestor

  class FileIngestor
    attr_accessor :digital_object_id, :original_filepath,
                  :derivative_filename, :derivative_dirpath, :derivative_format,
                  :copy

    attr_writer   :original_filename, :position,
                  :metadata, :raw, :digital_file_id, :digital_file

    # required params:
    # :original_filepath, :digital_object_id
    #
    # optional params:
    # :derivative_dirpath, :derivative_filename, :derivative_format, :digital_file,
    # :digital_file_id, :update_record
    def initialize(opts={})
      opts.each do |option, value|
        send "#{option}=".to_sym, value
      end

      required_params = [:original_filepath, :digital_object_id]
      unless required_params.map{|param| self.send(param)}.all?
        raise ArgumentError, "Required options: #{required_params.map(&:inspect).join(', ')}"
      end
    end

    def original_filename
      @original_filename ||= File.basename(original_filepath)
    end

    def derivative_filename
      @derivative_filename ||=  if derivative_format.nil?
                                  default_derivative_filename
                                else
                                  "#{default_derivative_filename}.#{derivative_format}"
                                end
    end

    def derivative_filepath
      return unless derivative_dirpath && derivative_filename
      File.join(derivative_dirpath, derivative_filename)
    end

    def digital_file
      @digital_file ||= DigitalFile.first :conditions => {
                                            :digital_object_id => digital_object_id,
                                            :original_filename => original_filename
                                          }
    end

    def digital_file_id
      @digital_file_id ||= digital_file.id
    end

    def digital_object
      @digital_object ||= DigitalObject.find_by_id(digital_object_id)
    end

    def position
      @position ||= digital_file.position
    end

    def raw
      raise 'Abstract method'
    end

    def copy
      raise 'Abstract method'
    end

    def metadata(extractor_name=nil)
      raise 'Abstract method'
    end

    def ingest(&block)
      yield raw
    end

    private

    def default_derivative_filename
      return unless digital_file
      digital_file.derivative_filename ||
      ( digital_file && digital_file.position && digital_file.position.to_s.rjust(5,'0') )
    end

  end

end

