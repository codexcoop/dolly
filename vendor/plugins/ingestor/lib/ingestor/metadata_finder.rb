module Ingestor

  class MetadataFinder
    class << self
      attr_reader :registered_extractors

      def registered_extractor_names
        registered_extractors.keys
      end
    end

    @registered_extractors = {}

    attr_accessor :filepath, :extractor_name
    attr_writer   :metadata, :raw

    def initialize(opts={})
      raise ArgumentError, ":filepath option is required" unless opts[:filepath]
      self.filepath       = opts[:filepath]
      self.raw            = opts[:raw]
      self.extractor_name = opts[:extractor_name]
    end

    def raw
      @raw ||=  begin
                  MiniMagick::Image.open(filepath)
                rescue MiniMagick::Invalid
                  p "Could not open #{filepath}"
                end
    end

    def metadata
      return @metadata if @metadata
      run_extractors
      normalize_resolution
      @metadata ||= {}
    end

    def self.register(name, &block)
      registered_extractors[name.to_sym] = block
    end

    private

    def run_extractors
      if extractor_name
        self.metadata = self.class.registered_extractors[extractor_name.to_sym].call(filepath)
      else
        self.class.registered_extractors.values.each { |block| break if self.metadata = block.call(filepath) }
      end
    end

    def normalize_resolution
      return unless @metadata

      @metadata[:x_resolution] =
        (@metadata && @metadata[:x_resolution] && @metadata[:x_resolution].to_i) ||
        (raw && raw.x_ppi.to_i)
      @metadata[:y_resolution] =
        (@metadata && @metadata[:y_resolution] && @metadata[:y_resolution].to_i) ||
        (raw && raw.y_ppi.to_i)
    end

  end

  ##############################################################################

  MetadataFinder.register :exif_from_tiff do |filepath|
    EXIFR::TIFF.new(filepath).to_hash rescue nil
  end

  MetadataFinder.register :exif_from_jpeg do |filepath|
    EXIFR::JPEG.new(filepath).to_hash rescue nil
  end

  ##############################################################################

end

