module Ingestor

  module IngestSupportLogger
    attr_accessor :log

    def log
      @log ||= PersistentLogger.new(File.join(Rails.root, 'log', "#{lot_code}_processing.log"))
    end
  end

end

