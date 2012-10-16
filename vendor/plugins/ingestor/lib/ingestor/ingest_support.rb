module Ingestor

  class IngestSupport
    include IngestSupportLogger
    include IngestSupportTables
    ModelExt.extend_models

    attr_accessor :docs_dirpath,              # where the files with lists are stored
                  :dirs_list_filename,        # a text file with a list of the directories to process
                  :dirs_list_filepath,        # idem, but with full path
                  :files_list_filename,       # a text file with a list of the files to process
                  :files_list_filepath,       # idem, but with full path
                  :master_dirs_glob_pattern,  # the name of the individual dirs is the name of the TmpIngestDir obj
                  :images_subpath,            # "Master" for example
                  :dirs_dump_name,            # where the content of wip.tmp_ingest_dirs table is saved as yaml
                  :files_dump_name,           # where the content of wip.tmp_ingest_files table is saved as yaml
                  :processing_strategies,     # on demand processing definition
                  :lot_code,                  # a unique explicative identifier of the lot of dirs being processed
                  :institution_id,
                  :digital_collection_id,
                  :user_id

    def initialize(ingest_opts={})
      required_params = [ :lot_code,
                          :docs_dirpath,
                          :dirs_list_filename,
                          :files_list_filename,
                          :institution_id,
                          :digital_collection_id,
                          :user_id,
                          :master_dirs_glob_pattern ]

      unless required_params.to_set.subset?(ingest_opts.keys.to_set)
        raise(ArgumentError, "required params: #{required_params.map(&:inspect).join(', ')}")
      end
      ingest_opts.each { |opt_name, value| send("#{opt_name}=".to_sym, value) }
    end

    # Usage:
    # - define a new strategy: processing_strategies :my_strategy do |my_file, my_file_ingestor| ... end
    # - running the strategy: processing_strategies[:my_strategy].call(my_file, my_file_ingestor)
    # my_file, my_file_ingestor can be whatever you want to call your block with
    def processing_strategies(strategy_name=nil, &block)
      @processing_strategies ||= {}

      if strategy_name && block_given?
        @processing_strategies[strategy_name] = block
      else
        @processing_strategies
      end
    end

    def lot_code=(lot_code)
      @lot_code = Ingestor.to_normal_dirname(lot_code.to_s, '_')
      # OPTIMIZE: possibile semplificazione @lot_code = lot_code
    end

    def dirs_dump_name
      @dirs_dump_name ||= "#{lot_code}_dirs_dump.yml.txt"
    end

    def files_dump_name
      @files_dump_name ||= "#{lot_code}_files_dump.yml.txt"
    end

    def dirs_list_filepath
      @dirs_list_filepath ||= File.join(docs_dirpath, dirs_list_filename)
    end

    def files_list_filepath
      @files_list_filepath ||= File.join(docs_dirpath, files_list_filename)
    end

    def populate_tmp_dirs_table_from_file
      TmpIngestDir.destroy_lot(lot_code)
      TmpIngestDir.reset_pk
      log.debug("Parsing #{dirs_list_filepath}")
      File.open(dirs_list_filepath) do |file|
        lines = file.enum_for(:each_line)
        lines.each do |line|
          line.chomp!
          next if line.empty?
          dirname = line.split('/').select(&:present?).last
          tmp_dir = TmpIngestDir.find_or_create_by_lot_code_and_dirname(lot_code, dirname)
          tmp_dir.update_attributes!(:dirpath => "#{line}/Master", :lot_code => lot_code)
        end
      end
      log.debug("Created #{TmpIngestDir.count('id', :conditions => {:lot_code => lot_code})} tmp dir records")
    end

    def populate_tmp_files_table_from_file
      TmpIngestFile.destroy_lot(lot_code)
      TmpIngestFile.reset_pk
      log.debug("Parsing #{files_list_filepath}")
      File.open(files_list_filepath) do |file|
        TmpIngestFile.transaction do
          file.enum_for(:each_line).inject({:previous_dirname => '', :previous_dir => nil}) do |memo, line|
            line.chomp!
            next if line.blank?
            tokens    = line.split("/")
            dirname   = tokens[1]
            filename  = tokens.last
            tmp_dir   = if memo[:previous_dirname] != dirname
                          log.debug %Q{Creating tmp "tiff" file records for dir "#{dirname}"}
                          TmpIngestDir.find_by_lot_code_and_dirname(lot_code, dirname)
                        else
                          memo[:previous_dir]
                        end

            if tmp_dir
              tmp_dir.tmp_ingest_files.create!(
                :line               => line,
                :original_filename  => filename,
                :original_object_id => tmp_dir.original_object_id
              )
            else
              log.debug %Q{There is no TmpIngestDir record named "#{dirname}"}
            end

            {:previous_dirname => dirname, :previous_dir => tmp_dir}
          end
        end
      end
    end

    # TODO: [Luca] ripristinare e fixare quando sarà usato
    def add_pdf_to_tmp_files_table
      #TmpIngestDir.for_lot(lot_code).each do |dir|
      #  log.debug(%Q{Creating tmp "pdf" file record for dir "#{dir.dirname}"})
      #  TmpIngestFile.create!(
      #    :line               => "Brescia/#{dir.dirname}/#{dir.dirname}.pdf",
      #    :original_filename  => "#{dir.dirname}.pdf",
      #    :tmp_ingest_dir_id     => dir.id,
      #    :original_object_id => dir.original_object_id,
      #    :mime_type          => "application/pdf"
      #  )
      #end
    end

    def dump_tmp_table(model_class, dump_filename)
      log.debug(%Q{Dumping #{model_class.table_name} to #{dump_filename}})
      File.open(File.join(docs_dirpath, dump_filename), 'w') do |dump_file|
        model_class.for_lot(lot_code).each { |dir_rec| dump_file.puts dir_rec.attributes.to_yaml.pretty_inspect }
      end
    end

    def restore_tmp_table(model_class, dump_filename)
      log.debug(%Q{Restoring #{model_class.table_name} from #{dump_filename}})
      File.open(File.join(docs_dirpath, dump_filename)) do |dump_file|
        model_class.transaction do
          model_class.delete_all
          model_class.reset_pk

          dump_file.each_line do |line|
            params = YAML.load(eval(line))
            model_class.create! do |rec|
              rec.id = params.delete('id')
              rec.attributes = params
            end
          end

          model_class.reset_pk(model_class.maximum('id').to_i + 1)
        end
      end
    end

    def create_missing_original_objects
      log.debug "Creating missing original objects"
      TmpIngestDir.for_lot(lot_code).all(:conditions => {:original_object_is_new => true}).each do |dir|

        original_object = OriginalObject.new  :institution_id => institution_id,
                                              :title => "[TMP] #{dir.dirname.gsub(/_|\-/, ' ')}",
                                              :user_id => user_id
        original_object.save!
        # Tipo: materiale a stampa
        # original_object.entity_terms.create(:vocabulary_id => 39, :property_id => 91, :term_id => 12127)
        # Lingua: italiano
        # original_object.entity_terms.create(:vocabulary_id => 14, :property_id => 94, :term_id => 652)

        dir.update_attributes!(
          :original_object_id     => original_object.id,
          :original_object_is_new => true
        )
        log.debug %Q{Created new missing OriginalObject, ##{original_object.id}, for dir "#{dir.dirname}"}
      end
    end

    def create_digital_object_for(mime_type)
      file_type = mime_type.split('/').last
      TmpIngestDir.for_lot(lot_code).all(:conditions => {:digital_object_is_new => true}).each do |dir|
        digital_object = DigitalObject.create!({
          :digital_collection_id   => digital_collection_id,
          :user_id                 => user_id,
          :institution_id          => institution_id, # OPTIMIZE: probabile che si userà o user o institution (non tutti 2)
          :original_object_id      => dir.original_object_id,
          :master_dirpath          => dir.dirpath,
          :record_type             => 'TEXT' # OPTIMIZE remotissimo: potrebbe essere anche valore diverso da TEXT
        })
        # update the support table with data from new digital_object record
        dir.update_attributes! "#{file_type}_digital_object_id".to_sym => digital_object.id
        log.debug %Q{Created DigitalObject ##{digital_object.id}, for dir "#{dir.dirname}"}
      end
    end

    def create_digital_file_for(mime_type, tmp_file_record, dir, index)
      # create digital_file record
      digital_file = DigitalFile.create!({
        :user_id                => user_id,
        :digital_object_id      => dir.send("#{mime_type.split("/").last}_digital_object_id"),
        :original_content_type  => mime_type,
        :original_filename      => tmp_file_record.original_filename,
        :derivative_filename    => (index+1).to_s.rjust(5,'0') + (mime_type == 'application/pdf' ? '.pdf' : '.jpeg'),
        :original_position      => index+1,
        :position               => index+1
      })
      # update support table with data of the new digital_file record
      tmp_file_record.update_attributes!(
        :digital_file_id    => digital_file.id,
        :digital_object_id  => dir.tiff_digital_object_id,
        :original_object_id => dir.original_object_id,
        :mime_type          => mime_type
      )
    end

    # accepted arguments: 'image/tiff' or 'application/pdf'
    def create_digital_file_records_for(mime_type)
      TmpIngestDir.transaction do
        TmpIngestDir.for_lot(lot_code).each do |dir|
          tmp_file_records = dir.tmp_ingest_files.send("#{mime_type.split('/').last}_files")
          log.debug(%Q{Creating #{tmp_file_records.size} DigitalFile record(s), \
                      of type "#{mime_type}", for dir "#{dir.dirname}"}.squeeze(' '))
          tmp_file_records.each_with_index do |tmp_ingest_file, index|
            create_digital_file_for(mime_type, tmp_ingest_file, dir, index)
          end
        end
      end
    end

    def create_node_records
      TmpIngestDir.for_lot(lot_code).each do |tmp_ingest_dir|
        digital_object = tmp_ingest_dir.digital_object
        node_ids = digital_object.nodes.map(&:id) - [digital_object.toc.id]

        log.debug %Q{Destroying nodes for digital_object ##{tmp_ingest_dir.digital_object.id} }
        Node.delete_all(:id => node_ids)
        Node.reset_pk

        log.debug %Q{Resetting toc for digital_object ##{tmp_ingest_dir.digital_object.id} }
        digital_object.toc.update_attributes(:description => 'TOC', :digital_file_id => nil)

        log.debug %Q{Importing tmp_nodes in nodes for digital_object \
                    ##{tmp_ingest_dir.digital_object.id}, \
                    "#{tmp_ingest_dir.original_object.title}"}.squeeze(' ')
        tmp_ingest_dir.import_tmp_nodes
      end
    end

    def process_images_large(source_dirpath, digital_object)
      dir_ingestor = Ingestor::DirIngestor.new(
        :source               => source_dirpath,
        :destination          => digital_object.digital_object_paths[:large],
        :digital_object_id    => digital_object.id,
        :file_ingestor_class  => Ingestor::ImageIngestor,
        :logger               => log
      )

      dir_ingestor.each_file_ingestor do |image_ingestor, index|
        image_ingestor.ingest do |raw_magick_image|
          break unless raw_magick_image
          processing_strategies[:large].call(raw_magick_image, image_ingestor)

          image_ingestor.digital_file.update_attributes!({
              :user_id                  => user_id,
              :technically_valid        => image_ingestor.technically_valid?,
              :large_technical_metadata => MetadataFinder.new(:filepath => image_ingestor.derivative_filepath).metadata,
              :width_large              => raw_magick_image.width,
              :height_large             => raw_magick_image.height
          })
          log.debug "#{image_ingestor.original_filename} => #{image_ingestor.derivative_filepath.gsub((Rails.root.to_s+'/'),'')}"
        end
      end
    end

    def process_images_medium(source_dirpath, digital_object)
      ingest_options = {
        :source               => digital_object.digital_object_paths[:large],
        :destination          => digital_object.digital_object_paths[:medium],
        :digital_object_id    => digital_object.id,
        :file_ingestor_class  => Ingestor::ImageIngestor,
        :logger               => log
      }

      digital_object.each_file_ingestor(ingest_options) do |image_ingestor, index|
        image_ingestor.ingest do |raw_magick_image|
          break unless raw_magick_image
          processing_strategies[:medium].call(raw_magick_image, image_ingestor)
          log.debug "#{image_ingestor.original_filename} => #{image_ingestor.derivative_filepath.gsub((Rails.root.to_s+'/'),'')}"
        end
      end
    end

    def process_images_small(source_dirpath, digital_object)
      ingest_options = {
        :source               => digital_object.digital_object_paths[:large],
        :destination          => digital_object.digital_object_paths[:small],
        :digital_object_id    => digital_object.id,
        :file_ingestor_class  => Ingestor::ImageIngestor,
        :logger               => log
      }

      digital_object.each_file_ingestor(ingest_options) do |image_ingestor, index|
        image_ingestor.ingest do |raw_magick_image|
          break unless raw_magick_image
          processing_strategies[:small].call(raw_magick_image, image_ingestor)

          image_ingestor.digital_file.update_attributes!({
            :width_small  => raw_magick_image.width,
            :height_small => raw_magick_image.height
          })

          log.debug "#{image_ingestor.original_filename} => #{image_ingestor.derivative_filepath.gsub((Rails.root.to_s+'/'),'')}"
        end
      end
    end

    def process_images(options={})
      # should be an instance variable with default
      all_variants = [:large, :small, :medium]
      # should go in a separate method
      variants = (options[:only] ? [options[:only]].flatten : all_variants) - [options[:except]].flatten
      variants.delete_if { |variant| processing_strategies[variant].nil? }

      dirs = Dir[master_dirs_glob_pattern].sort

      if dirs.empty?
        log.debug "There are no dirs with the specified options"
        return
      end

      dirs.each do |master_dirpath|

        t0 = Time.now
        master_dirname    = master_dirpath.split('/')[-1]
        images_dirpath    = File.join(master_dirpath, images_subpath)
        tmp_ingest_dir    = TmpIngestDir.find_by_lot_code_and_dirname(lot_code, master_dirname)
        digital_object_id = tmp_ingest_dir.tiff_digital_object_id if tmp_ingest_dir
        digital_object    = DigitalObject.find_by_id( digital_object_id )

        should_skip = [
          digital_object.nil?,
          (options[:dirs] && !options[:dirs].include?(master_dirname)),
          (options[:digital_object_ids] && !options[:digital_object_ids].map(&:to_s).include?(digital_object_id.to_s))
        ]

        if should_skip.any?
          log.debug "#{master_dirname} can't be processed"
          next
        end

        log.debug %Q{-- Start processing "#{master_dirpath}" at #{t0}}

        process_images_large( images_dirpath, digital_object ) if variants.include?(:large)

        process_images_medium( digital_object.digital_object_paths[:large], digital_object ) if variants.include?(:medium)

        process_images_small( digital_object.digital_object_paths[:large], digital_object ) if variants.include?(:small)

        t1 = Time.now
        log.debug %Q{Processed "#{master_dirpath}" in #{Time.at(t1-t0).gmtime.strftime('%R:%S')}}
      end
    end

    def reset_entities_pks
      ActiveRecord::Base.transaction do
        log.debug "Resetting primary key sequences for entities:"
        log.debug "- nodes => next value: " + Node.reset_pk.to_s
        log.debug "- digital_files => next value: " + DigitalFile.reset_pk.to_s
        log.debug "- digital_objects => next value: " + DigitalObject.reset_pk.to_s
        log.debug "- original_objects => next value: " + OriginalObject.reset_pk.to_s
      end
    end

    def destroy_new_entities
      ActiveRecord::Base.transaction do
        log.debug "Deleting records:"
        log.debug "- " + Node.destroy_ingested_for_lot(lot_code).to_s + " nodes"
        log.debug "- " + DigitalFile.destroy_ingested_for_lot(lot_code).to_s + " digital_files"
        log.debug "- " + DigitalObject.destroy_ingested_for_lot(lot_code).to_s + " digital_objects"
        log.debug "- " + OriginalObject.destroy_ingested_for_lot(lot_code).to_s + " original_objects"

        log.debug "Updating counter cache columns"
        DigitalObject.perform_force_counter_cache_reset
        Institution.perform_force_counter_cache_reset

        reset_entities_pks
      end
    end

    def nullify_tmp_records
      ActiveRecord::Base.transaction do
        TmpIngestDir.nullify_lot(lot_code)
        TmpIngestFile.nullify_lot(lot_code)
        TmpIngestNode.nullify_lot(lot_code)
        log.debug "Selectively nullified tmp tables"
      end
    end

    def destroy_tmp_records
      ActiveRecord::Base.transaction do
        log.debug "Deleting tmp records:"
        log.debug "- " + TmpIngestNode.destroy_lot(lot_code).to_s + " tmp_ingest_nodes"
        log.debug "- " + TmpIngestFile.destroy_lot(lot_code).to_s + " tmp_ingest_files"
        log.debug "- " + TmpIngestDir.destroy_lot(lot_code).to_s + " tmp_ingest_dirs"

        log.debug "Resetting primary key sequences for tmp entities"
        TmpIngestNode.reset_pk
        TmpIngestFile.reset_pk
        TmpIngestDir.reset_pk
      end
    end

    def rollback
      log.debug "Rollback #{lot_code}\n"
      ActiveRecord::Base.transaction do
        destroy_new_entities
        destroy_tmp_records
        log.debug "\nRollback successful"
      end
    end

    def perform(&block)
      if block.arity < 1
        self.instance_eval &block
      else
        yield self
      end
      log.close
    end

  end # class IngestSupport

end

