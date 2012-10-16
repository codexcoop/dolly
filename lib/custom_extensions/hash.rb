module CustomExtensions
  module Hash

    unless method_defined? :assert_required_keys
      def assert_required_keys(*keys)
        required_keys = [*keys].flatten
        if (self.keys & required_keys).size < required_keys.size
          raise ArgumentError, "The following options are required: :#{required_keys.join(', :')}."
        end
      end
    end

    unless method_defined? :uniq_by!
      def uniq_by!(&block)
        self.replace(::Hash[*self.to_a.uniq_by(&block).flatten])
      end
    end

    unless method_defined? :uniq_by
      def uniq_by(&block)
        self.dup.uniq_by!(&block)
      end
    end

  end
end

