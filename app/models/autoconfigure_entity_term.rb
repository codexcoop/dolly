module AutoconfigureEntityTerm
  def self.included(klass)
    klass.class_eval do

      attr_accessor :term_code,
                    :term_it,
                    :term_en,
                    :term_translation_coalesce,
                    :term_vocabulary_id,
                    :term_user_id,
                    :term_is_new_record

      def term_translation_coalesce
        @term_translation_coalesce || self.term_it || self.term_en || self.term_code
      end

      before_validation :set_property_and_vocabulary

      belongs_to :vocabulary
      validates_presence_of :vocabulary_id

      belongs_to :property
      validates_presence_of :property_id

      def self.associated_entity_name(klass)
        klass.name.tableize.singularize.gsub(/_term/,'')
      end

      belongs_to :term, :counter_cache => :entity_terms_count
      validates_presence_of :term_id, :unless => :associated_term_is_new_record?

      belongs_to associated_entity_name(klass).to_sym
      accepts_nested_attributes_for :term,
                  :allow_destroy => false,
                  :reject_if => proc{ |attrs|
                    attrs['it'].blank? ||
                    Term.find(:first, :conditions => {:it => attrs['it'], :vocabulary_id => attrs['vocabulary_id'] })
                  }

      private

      def associated_term_is_new_record?
        self.term_is_new_record
      end

      def set_property_and_vocabulary
        self.property_id = self.property.id if self.property.id unless self.property_id
        self.vocabulary_id = self.term.vocabulary_id if self.term.vocabulary_id unless self.vocabulary_id
      end

    end
  end
end

