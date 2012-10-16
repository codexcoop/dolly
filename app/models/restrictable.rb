module Restrictable
  module ClassMethods
    def restrict_destroy_if_dependent(*dependencies)
      before_destroy do |record|
        actual_dependencies = record.actual_dependencies(*dependencies)
        if actual_dependencies.any?
          raise ActiveRecord::StatementInvalid,
                "Deletion impossible because of one or more dependent #{actual_dependencies.join(', ')} records"
        end
      end
    end

    def restrict_destroy_if_restrictable_by_nature(opts={})
      before_destroy do |record|
        if record.is_restrictable_record?(opts)
          raise ActiveRecord::StatementInvalid,
                "Deletion impossible because the record is restrictable by its own nature"
        end
      end
    end
  end
end

module Restrictable
  def self.included(klass)
    klass.extend(Restrictable::ClassMethods)
  end

  def is_restrictable_record?(opts={})
    opts.assert_required_keys :flag_fields
    opts.assert_valid_keys :flag_fields

    values = [opts[:flag_fields]].flatten.map do |flag_field|
      self.send(flag_field.to_sym)
    end

    values.any?(&:present?)
  end

  def actual_dependencies(*dependencies)
    dependencies.select{|dependency| has_dependents_for?(dependency)}
  end

  def has_actual_dependencies?(*dependencies)
    actual_dependencies(*dependencies).any?
  end

  def has_dependents_for?(dependency)
    if has_restrictable_macro_type?(dependency.to_sym)
      if has_counter_cache_for?(dependency.to_sym)
        self.send(:"#{dependency.to_s}_count") > 0
      else
        puts dependency
        puts self.send(dependency.to_sym)
        self.send(dependency.to_sym).size > 0 # 'size' use cached query if present, while 'count' fires a query each time
      end
    end
  end

  def has_counter_cache_for?(dependency)
    self.respond_to?(:"#{dependency.to_s}_count")
  end

  def has_restrictable_macro_type?(dependency)
    if self.respond_to?(dependency.to_sym)
      self.class.reflect_on_association(dependency.to_sym).macro.included_in?([:has_many, :has_one])
    end
  end

end

