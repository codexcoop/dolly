module Ingestor

  class ImageIngestor < FileIngestor

    def raw
      @raw ||=  begin
                  MiniMagick::Image.open(original_filepath)
                rescue MiniMagick::Invalid => e
                  p "MiniMagick::Invalid: #{e}"
                end
    end

    def metadata(extractor_name=nil)
      @metadata ||= MetadataFinder.new(
                      :filepath => original_filepath,
                      :raw => raw,
                      :extractor_name => extractor_name
                    ).metadata
    end

    def technically_valid?
      metadata[:x_resolution].to_i >= 400 && metadata[:y_resolution].to_i >= 400
    end

    def technically_acceptable?
      metadata[:x_resolution].to_i >= 300 && metadata[:y_resolution].to_i >= 300
    end

    def copy
      raise RuntimeError, "the raw file is nil" if raw.nil?
      raise RuntimeError, "the raw file must implement a 'copy' method" unless raw.respond_to?(:copy)
      @copy ||= raw.copy
    end

    def ingest(&block)
      yield raw
    end

  end

end

