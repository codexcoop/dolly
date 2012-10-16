# to be included only in ActiveRecord subclasses
module Trimmer
  def self.included klass
    klass.extend(ClassMethods)
  end

  module ClassMethods

    def trimmed_fields *field_list
      before_validation do |record|
        field_list.each{|f| record[f] = record[f].squish if record[f] }
      end
    end

  end

end

