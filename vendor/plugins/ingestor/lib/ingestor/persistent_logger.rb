module Ingestor

  class PersistentLogger < (defined?(BasicObject) ? BasicObject : BlankSlate)
    attr_accessor :stdout, :file

    def initialize(path)
      self.stdout = Logger.new(STDOUT)
      self.file   = Logger.new(path)
    end

    def method_missing(*args)
      stdout.send(*args)
      file.send(*args)
    end
  end

end

