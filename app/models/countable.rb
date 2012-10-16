# TODO: bring sanity to Countable
# TODO: move Countable to lib
module Countable
  # TODO: implement self.included extend ClassMethods in Countable

  module ClassMethods

    # si chiama con: after_save :update_terms_count_in_vocabularies
    def update_terms_count_in_vocabularies
      Vocabulary.update_counters self.vocabulary_id, :terms_count => 1
    end

    # effettua un aggiornamento di tutti record tramite sql,
    # perché il counter cache di rails funziona solo per create e destroy
    # => per chiamarlo: after_update {update_counter_caches_in :model => 'project'}
    # TODO: aggiungere la gestione dell'opzione :institution_only
    def update_counter_caches_in(options={})
      options.assert_valid_keys(:model, :foreign_key, :counter_field, :institution_only)

      name_of_model_to_update = options[:model].tableize.singularize.classify
      counter_field = (options[:counter_field] || "#{self.name.tableize}_count").to_sym
      foreign_key = (options[:foreign_key] || "#{name_of_model_to_update.tableize.singularize}_id").to_sym

      new_counts = self.count(:group => foreign_key)

      new_counts.each_pair{|k,v| new_counts[k]={counter_field => v}}

      name_of_model_to_update.constantize.update(new_counts.keys, new_counts.values)

      all_ids_of_model_to_update = name_of_model_to_update.constantize.all(:select => 'id').map(&:id)

      ids_to_zerify = all_ids_of_model_to_update - new_counts.keys

      ord_hash = ActiveSupport::OrderedHash.new

      ids_to_zerify.each{|id| ord_hash[id]={counter_field => 0}}

      name_of_model_to_update.constantize.update(ord_hash.keys, ord_hash.values)
    end

  end

end

