require 'strscan'

module CustomExtensions
  module String
    CHARS_FOR_RANDOM_STRING = [ ('a'..'z').to_a, ('A'..'Z').to_a, ('0'..'9').to_a ].flatten

    unless method_defined? :custom_normalize
      def custom_normalize
        self.mb_chars.
             normalize(:kd).
             gsub(/[^\x00-\x7F]/n,'').
             gsub(/\s+/, ' ').
             gsub(/[^a-zA-Z0-9]/,'_').
             gsub(/_+/,'_').
             downcase.
             match(/[^_](.*)[^_]/).
             to_s
      end
    end

    unless method_defined? :custom_sql_escape
      def custom_sql_escape
        self.gsub("\\","\\\\\\\\").
             gsub("'","''")
      end
    end

    unless method_defined? :remove
      def remove(match)
        if match.is_a? String or match.is_a? Regexp
          self.gsub!(match, '')
        else
          raise TypeError, "Argument must be a string or a regexp."
        end
      end
    end

    unless method_defined? :custom_to_lines
      def custom_to_lines
        # self.split("\n").map(&:strip).delete_if{|str| str.size == 0}
        self.strip.lines.map.reject{|line| line.empty? || line == "\n"}.map{|line| line.gsub(/\n$/,'') } #  || line.match(/^\n+|\n+$/)
      end
    end

  end
end

