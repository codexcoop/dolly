module Ingestor

  module PrimaryKeyReset

    def reset_pk(next_value = nil)
      next_value ||= self.maximum(:id).to_i + 1
      self.connection.execute("ALTER SEQUENCE #{table_name}_id_seq RESTART WITH #{next_value}")
      next_value
    rescue ActiveRecord::StatementInvalid => e
      puts "PrimaryKeyReset not supported by #{connection.adapter_name}, #{e}"
    end

  end

end

