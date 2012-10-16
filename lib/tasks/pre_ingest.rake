# Conventions:
# - the master digital objects are grouped in lots
# - each lot is stored in a directory, named with a unique normalized name
# - each lot has many subdirectories, one per digital object, named with a unique normalized name
# - each digital object has a subdirectory named "Master" containing the master files
#
# Example:
# - lot
# -- digital-object-1
# -- digital-object-2
# --- Master
# ---- file-1.tiff
# ---- file-2.tiff
#

namespace :pre_ingest do

  lot = "bergamo_3" # Could be argument of each task
  tmp_dir = Rails.root.to_s + "/public/tmp_digital_files"
  pwd = tmp_dir + "/" + lot
  trash_pwd = pwd + "-scarti"

  def normalize_name(string, separator='-')
    ActiveSupport::Inflector.transliterate(string).to_s.
                             gsub(/[^a-zA-Z0-9_]/, separator).
                             squeeze(separator).
                             sub(Regexp.new("\\#{separator}$"), '')
  end

  desc "Normalize dirs names"
  task :normalize_dirs => :environment do

    dirs = Dir[File.join(pwd, '**')]
    Dir.chdir(pwd)

    dirs.each do |dir|
      src = File.basename(dir)
      dest = normalize_name(src)
      FileUtils.mv(src, dest, :verbose => true) unless src == dest
    end

  end

  desc "[Only for non-standard structures] Rename dirs names by adding a prefix, i.e. the parent dir basename"
  task :prefix_dirs => :environment do

    dirs = Dir.glob("#{pwd}/*/*/")

    dirs.each do |dir|
      parent_dir = File.dirname(dir)
      prefix = File.basename(parent_dir)
      current_name = File.basename(dir)
      dest = parent_dir + "/" + prefix + "-" + current_name + "/"
      FileUtils.mv(dir, dest, :verbose => true)
    end

  end

  desc "Normalize subdirs names: 'Master'"
  task :normalize_subdirs => :environment do

    dirs = Dir[File.join(pwd, '**', '')].grep(/master/i)

    dirs.each do |dir|
      parent_dir = File.dirname(dir)
      tmp_dest = File.join(parent_dir, 'tmp_Master')
      dest = File.join(parent_dir, 'Master')
      FileUtils.mv(dir, tmp_dest, :verbose => true)
      FileUtils.mv(tmp_dest, dest, :verbose => true)
    end

  end

  desc "Prune not needed files: derivatives (and PDF for now)"
  task :prune => :environment do

    dirs = Dir[File.join(pwd, '**')]

    dirs.each do |dir|
      dirname = File.basename(dir)
      trash_dir = File.join(trash_pwd, dirname)
      FileUtils.mkdir_p(trash_dir, :verbose => true) unless File.directory? trash_dir

      entries = Dir[File.join(dir, '*')].reject{|e| e =~ /\/Master$/ }
      entries.each do |entry|
         dest = File.join(trash_dir, File.basename(entry))
         FileUtils.mv(entry, dest, :verbose => true)
      end
    end
  end

  desc "Remove subdirectories of not needed derivatives"
  task :rm_derivatives => :environment do

    dirs = Dir[File.join(trash_pwd, '**/*/*/')].reject{|d| d =~ /PDF/i }

    dirs.each do |dir|
      FileUtils.rm_rf(dir, :secure => true, :verbose => true)
    end
  end

  desc "Remove local metafiles: Thumbs.db and .DS_Store"
  task :rm_metafiles => :environment do

    metafiles = Dir[File.join(pwd, '**', '*')].grep(/Thumbs\.db/)
    Dir.glob([File.join(pwd, '**', '*')], File::FNM_DOTMATCH).grep(/\.DS_Store/).each do |file|
      metafiles << file
    end

    metafiles.each do |mf|
      FileUtils.rm(mf, :verbose => true)
    end

    puts "*************************************************************************"
    puts "\nNow EXECUTE finder.sh (to make lists of ingestable dirs and master files)\n\n"
  end

  desc "Check if there are non standard TIFF images"
  task :check_tiff => :environment do
    conditions = "line ILIKE '#{lot}/%.tif'"
    count = TmpIngestFile.count(:conditions => conditions)
    puts "Checking #{count} TIFF images..."

    TmpIngestFile.find_each(:conditions => conditions) do |im|
      im_path = tmp_dir + "/" + im.line
      system "identify -ping #{im_path} | grep warning"
    end

  end

  # OPTIMIZE: per ora usare finder.sh
  # Vedi Ruby Class: Pathname
  desc "TODO: Make sorted lists of ingestable dirs and master files (excluding metafiles)"
  task :list => :environment do
    puts "Nothing done"
    # dirs = Dir[File.join(pwd, '**')]
    # 
    # File.open(tmp_dir + '/bergamo_1_dirs.txt', 'w+') do |file|
    #   dirs.each { |dir| file.puts "bergamo_1/" + File.basename(dir) }
    # end

  end

end

# TODO: task with argument (e verificare che argument sia normalized e cartella relativa esista)

# OPTIMIZE: [LOW] check if normalized pathnames are unique, otherwise exit
# OPTIMIZE: [LOW] logger (store output messages in a log file)
# Snippet utili one line:
# Dir["*"].each { |file| File.rename( file, file.upcase ) }
# Dir['app/*/'].map { |a| File.basename(a) }
