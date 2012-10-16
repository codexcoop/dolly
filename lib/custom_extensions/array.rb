module CustomExtensions
  module Array

    unless method_defined? :uniq_by!
      def uniq_by!(&block)
        self.delete_if do |item|
          self.take(self.index(item)).any? do |previous|
            yield(item) == yield(previous)
          end
        end
      end
    end

    unless method_defined? :uniq_by
      def uniq_by(&block)
        self.dup.uniq_by!(&block)
      end
    end

    unless method_defined? :not_include?
      def not_include?(obj)
        !include?(obj)
      end
    end

    unless method_defined? :assert_valid_values
      def assert_valid_values(*values)
        unless self.all? {|v| values.include? v}
          raise ArgumentError, "Only the values :#{values.join(', :')} are valid."
        end
      end
    end

  end
end

