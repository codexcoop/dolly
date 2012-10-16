namespace :batch do

  # TODO: collocazione provvisoria. Starà in lib/tasks una volta che Ingestor andrà in lib

  desc "Update image dimensions"
  task :update_dimensions => :environment do

    puts "Finding digital_objects with no dimensions..."
    @digital_objects = DigitalObject.find(:all,
      :select => "DISTINCT digital_objects.id",
      :joins => :digital_files,
      :conditions => "digital_files.large_technical_metadata is null
                    OR digital_files.width_large is null
                    OR digital_files.height_large is null",
      :order => "digital_objects.id")

    puts "Updating dimensions..."
    @digital_objects.each do |digital_object|
      digital_files = digital_object.digital_files

      puts "- ##{digital_object.id}: #{digital_files.size} files"
      complain = true
      digital_files.each do |digital_file|

        begin
          large_filepath = digital_file.filesystem_path(:variant => 'L')
          small_filepath = digital_file.filesystem_path(:variant => 'S')

          large   = MiniMagick::Image.open(large_filepath)
          small   = MiniMagick::Image.open(small_filepath)
          large_technical_metadata = Ingestor::MetadataFinder.new(:filepath => large_filepath).metadata.to_yaml

          # NOTE: technically_valid è vuoto. Da popolare se serve da qualche parte, ma ne dubito...
          sql = " large_technical_metadata = '#{large_technical_metadata}',
                  width_small = #{small[:width]}, height_small = #{small[:height]},
                  width_large = #{large[:width]}, height_large = #{large[:height]}"

          DigitalFile.update_all(sql, {:id => digital_file.id})
          complain = true
        rescue Errno::ENOENT => e
          puts e.message if complain
          complain = false
        end
      end
    end

  end

end