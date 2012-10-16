require 'exifr'
require 'mini_magick'

require 'ingestor/constants'
require 'ingestor/mini_magick_ext'
require 'ingestor/ingest_support_logger'
require 'ingestor/persistent_logger'
require 'ingestor/tmp_tables'

require 'ingestor/metadata_finder'
require 'ingestor/file_ingestor'
require 'ingestor/image_ingestor'
require 'ingestor/dir_ingestor'
require 'ingestor/dir_ingest_support'

require 'ingestor/active_record_ext'
require 'ingestor/ingest_support'
require 'ingestor/model_ext'
require 'ingestor/tmp_node'
require 'ingestor/tmp_tree'

require 'tmp_ingest_dir'
require 'tmp_ingest_file'
require 'tmp_ingest_node'

module Ingestor

  def self.to_normal_dirname(dirname, separator='-')
    ActiveSupport::Inflector.transliterate(dirname).
                            to_s.
                            gsub(/[^a-zA-Z0-9]/, separator). # replace non alphanum chars with separator
                            gsub(/([a-zA-Z])(\d)/, '\1' + separator + '\2'). # put a separator before digits
                            gsub(/(\d)([a-zA-Z])/, '\1' + separator + '\2'). # put a separator after digits
                            squeeze(separator). # at most one consecutive separator
                            sub(Regexp.new("\\#{separator}$"), '') # remove trailing separator
    # NOTE: alternativa (al modo di url tutto minuscolo)
    # "stringa".parameterize.to_s.gsub(/[^a-zA-Z0-9]/, separator)

  end

end

