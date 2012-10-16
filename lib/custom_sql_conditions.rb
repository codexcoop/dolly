module CustomSqlConditions

  # Builds a correctly interpolated string with attributes checked for sql_comparison
  # and linked by the bool_operation.
  # The interpolation follows the rules suggested by ActiveRecord for complex conditions
  # Values could also be enumerables: in such a case, all the values are put
  # with the same bool_operation for the correspondent attribute (key of the hash)
  #     bool_operation => OR, AND
  #     sql_comparison => =, <, >, LIKE, ILIKE...
  #
  # usage example:
  # conditions = {"subject_names.name" => ["%arte%", "%sacra%"], :qualifier_id => [1,2,3], "institution_id" => 4}
  # interpolate_conditions(:and, :ilike, conditions)
  # ...
  # => [
  #       "qualifier_id ILIKE :qualifier_id_0 AND
  #        qualifier_id ILIKE :qualifier_id_1 AND
  #        qualifier_id ILIKE :qualifier_id_2 AND
  #        subject_names.name ILIKE :subject_names_name_0 AND
  #        subject_names.name ILIKE :subject_names_name_1 AND
  #        institution_id ILIKE :institution_id_0",
  #       {:qualifier_id_2=>3,
  #        :subject_names_name_0=>"%arte%",
  #        :subject_names_name_1=>"%sacra%",
  #        :institution_id_0=>4,
  #        :qualifier_id_0=>1,
  #        :qualifier_id_1=>2}
  #     ]
  # OPTIMIZE: this method could be splitted for better readablity
  def interpolate_conditions(bool_operation, sql_comparison, conditions_hash)
    snippets = []
    array_for_values = []

    conditions_hash.delete_if{|k,v| v.blank?}.each_pair do |key,values|
      [values].flatten.each_with_index do |value, index|
        snippets << "#{key.to_s} #{sql_comparison.to_s.upcase} :#{key.to_s.gsub(".", "_")}_#{index}"
        array_for_values << "#{key.to_s.gsub(".", "_")}_#{index}".to_sym << value
      end
    end
    interpolated_string = snippets.join(" #{bool_operation.to_s.upcase} ")
    hash_of_values = Hash[*array_for_values.flatten]

    [interpolated_string, hash_of_values]
  end

  def mix_interpolated_conditions(bool_operation, *interpolated_conditions_arrays)
    interpolated_string = interpolated_conditions_arrays.map{|a| "(#{a.first})"}.join(" #{bool_operation.to_s.upcase} ")
    hash_of_values = Hash[*interpolated_conditions_arrays.map{|a| a.last.to_a}.flatten]

    [interpolated_string, hash_of_values]
  end


end

