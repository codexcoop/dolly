require 'tempfile'

namespace :bergamo_1 do

  label = "bergamo_1"

  task_params = {
    :lot_code                 => label,
    :docs_dirpath             => File.join(Rails.root, "doc", "#{label}-info"),
    :dirs_list_filename       => "#{label}_dirs.txt",
    :files_list_filename      => "#{label}_files.txt",
    :institution_id           => 2,
    :digital_collection_id    => 2,
    :user_id                  => 2,
    :master_dirs_glob_pattern => "#{Rails.root}/public/tmp_digital_files/#{label}/*",
    :images_subpath           => "Master"
  }

  desc "Setup tmp tables parsing list files"
  task :setup_tmp_tables => :environment do
    Ingestor::IngestSupport.new(task_params).perform do
      create_support_tables
      populate_tmp_dirs_table_from_file
      execute <<-SQL
         UPDATE wip.tmp_ingest_dirs
         SET original_object_id = bergamo_1_mappings.original_object_id,
             tiff_digital_object_id = bergamo_1_mappings.digital_object_id
         FROM wip.bergamo_1_mappings
         WHERE tmp_ingest_dirs.dirname = bergamo_1_mappings.dirname
           AND tmp_ingest_dirs.lot_code = '#{lot_code}'
      SQL
      dump_tmp_table(TmpIngestDir, "#{lot_code}_1_dirs_dump.yml.txt")
      #restore_tmp_table(TmpIngestDir, 'bergamo_1_dirs_dump.yml.txt')
      populate_tmp_files_table_from_file
      #add_pdf_to_tmp_files_table
    end
  end

  desc "Process tables that contain doc/bergamo_1-info/"
  task :process_tmp_tables => :environment do
    Ingestor::IngestSupport.new(task_params).perform do
      destroy_new_entities
      create_missing_original_objects
      create_digital_object_for('image/tiff')
      create_digital_file_records_for('image/tiff')
      #create_digital_object_for('application/pdf')
      #create_digital_file_records_for('application/pdf')
    end
  end

  task :dirs_dump => :environment do
    Ingestor::IngestSupport.new(task_params).perform do
      dump_tmp_table(TmpIngestDir, "bergamo_1_dirs_dump.yml.txt")
    end
  end

  desc "Process bergamo_1's digital files and link them to already created records"
  task :process_images, [:dirs, :digital_object_ids] => :environment do |t, args|
    import = Ingestor::IngestSupport.new(task_params)

    import.processing_strategies :large do |magick_img, image_ingestor|
      magick_img.safe_resample(:min_resolution => 120, :min_square => 1280)
      magick_img.colorspace('Gray') if magick_img.grey?
      magick_img.format('jpeg')
      magick_img.quality('80')
      magick_img.write(image_ingestor.derivative_filepath)
    end

    import.processing_strategies :medium do |magick_img, image_ingestor|
      factor = magick_img.factor_to_fit(600) # a sort of custom resize to fit

      magick_img.thumbnail("#{(magick_img.width*factor).to_i}x#{(magick_img.height*factor).to_i}")
      magick_img.colorspace('Gray') if magick_img.grey?
      magick_img.format('jpeg')
      magick_img.quality('85')
      magick_img.write(image_ingestor.derivative_filepath)
    end

    import.processing_strategies :small do |magick_img, image_ingestor|
      factor = magick_img.factor_to_fit(200) # a sort of custom resize to fit

      magick_img.thumbnail("#{(magick_img.width*factor).to_i}x#{(magick_img.height*factor).to_i}")
      magick_img.colorspace('Gray') if magick_img.grey?
      magick_img.format('jpeg')
      magick_img.quality('85')
      magick_img.write(image_ingestor.derivative_filepath)
    end

    dirs                = args[:dirs].split("|") unless args[:dirs].to_s.empty?
    digital_object_ids  = args[:digital_object_ids].split("|") unless args[:digital_object_ids].to_s.empty?

    import.perform do
      process_images :only => [:large, :medium, :small],
                     :dirs => dirs,
                     :digital_object_ids => digital_object_ids
    end
  end

  task :noop => :environment do
    import = Ingestor::IngestSupport.new(task_params)
    pp import
  end

  task :rollback => :environment do
    import = Ingestor::IngestSupport.new(task_params)
    import.perform do
      rollback
    end
  end

end

