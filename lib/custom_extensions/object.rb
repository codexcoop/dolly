module CustomExtensions
  module Object

    unless method_defined? :included_in?
      def included_in?(*others)
        others = [others].flatten
        if others.respond_to? :include?
          others.include? self
        else
          raise ArgumentError, %Q{Argument object must respond to ":include?" }
        end
      end
    end

  end
end

