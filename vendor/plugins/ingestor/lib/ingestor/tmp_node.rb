module Ingestor

  class TmpNode
    attr_accessor :original_filename, :tokens, :date, :issue, :page, :supplement,
                  :edition, :level, :parent, :children, :description,
                  :describe_level, :define_children, :leaf, :node_id,
                  :tmp_ingest_file_id, :digital_file_id

    def initialize(attributes)
      required_attributes = ['digital_file_id', 'tmp_ingest_file_id', 'original_filename']
      unless attributes.values.all? && required_attributes == required_attributes & attributes.keys
        raise ArgumentError, %Q{#{required_attributes.inspect} are required}
      end
      attributes.each { |attribute, value| send "#{attribute}=", value }
    end

    # => ["L'eco della Provincia Iriense", "18530503", "96 sup", "0002"]
    def tokens
      @tokens ||= original_filename.split('.')[0..-2].join('.').split('_')
    end

    def date
      @date ||= Date.strptime(tokens[-3], '%Y%m%d')
    end

    def formatted_date
      {
        :long => I18n.localize(date, :locale => 'it', :format => "%e %B %Y").downcase.strip,
        :year => date.year
      }
    end

    def issue
      @issue ||= tokens[-2].to_i
    end

    def page
      @page ||= tokens[-1].to_i
    end

    def supplement(marker='sup')
      @supplement ||= ( tokens[-2] =~ Regexp.new("#{marker}", 'i') ? 1 : 0 )
    end

    def edition(marker='bis')
      @edition ||= ( tokens[-3] =~ Regexp.new("#{marker}", 'i') ? 2 : 1 )
    end

    def children
      @children ||= []
    end

    def children=(children)
      children.each{|child| child.parent = self}
      @children = children
    end

    def root?
      level == 0
    end

    def to_params
      {
        :tmp_ingest_file_id => tmp_ingest_file_id,
        :description        => description,
        :digital_file_id    => digital_file_id
      }
    end

  end # class TmpNode

end

