# to be included only in ActiveRecord subclasses
module CommonValidations
  def self.included(klass)
    klass.extend(ClassMethods)
    klass.class_eval do
      include CommonRegexp
    end
  end

  module ClassMethods
    def validate_format_if_present(attr_name, opts={})
      validation_regex =  if opts[:with].is_a?(Regexp)
                            opts[:with]
                          else
                            send(opts[:with].to_sym)
                          end

      define_presence_method_for(attr_name)

      validates_format_of attr_name.to_sym,
                          :with => validation_regex, # see CommonRegexp module in /lib
                          :if => "#{attr_name}_present?".to_sym
    end

    def define_presence_method_for(attr_name)
      define_method "#{attr_name}_present?" do
        send(attr_name.to_sym).present? if respond_to?(attr_name.to_sym)
      end
    end
  end

end

