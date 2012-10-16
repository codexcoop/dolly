module CustomExtensions
  module Dir

    module ClassMethods

      def entries_excluding_dirs(dir)
        return unless File.directory?(dir)
        glob(File.join(dir, '*')).delete_if{|file| File.directory?(file) }
      end

    end
  end
end

