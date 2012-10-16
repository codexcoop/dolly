module Descriptor

  def self.included(klass)
    klass.extend ClassMethods
  end

  def define_singleton_description_for(value, method_name)
    (class << value; self; end).instance_exec(method_name) do
      define_method(method_name){|*args| yield(self, *args)} unless self.frozen?
    end
  end

  module ClassMethods

    def define_description_for_attribute(method, description_method=:description, &block)
      define_method(method.to_sym) do |*original_args|
        begin
          super(*original_args).
          tap{|value| define_singleton_description_for(value, description_method, &block)}
        rescue Exception => e
          puts e.inspect
        end
      end
    end

    def define_description_for(method, description_method=:description, &block)
      return unless method_defined? method
      alias_method "original_#{method}".to_sym, method.to_sym
      define_method(method.to_sym) do |*original_args|
        send("original_#{method}".to_sym, *original_args).
        tap{|value| define_singleton_description_for(value, description_method, &block)}
      end
    end

  end # ClassMethods
end

