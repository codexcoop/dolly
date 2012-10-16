module CustomCounterCachable

  def self.included(klass)
    klass.extend(CustomCounterCachable::ClassMethods)
  end

  module ClassMethods

    def force_counter_cache_reset(opts={})
      opts.each_pair do |counter_field, association|
        associated_table = self.reflect_on_association(association.to_sym).klass.table_name.to_s
        association_field = self.reflect_on_association(association.to_sym).primary_key_name.to_s
        ActiveRecord::Base.connection.execute <<-SQL
          UPDATE #{self.table_name}
          SET #{counter_field.to_s} = (
            SELECT COUNT(*) FROM #{associated_table}
            WHERE #{associated_table}.#{association_field} = #{self.table_name}.#{self.primary_key}
          )
        SQL
      end
    end

  end
end

