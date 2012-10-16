module Ingestable
  module Constants

    MIN_SQUARE_LARGE    = 1280
    SQUARE_MEDIUM       =  600
    SQUARE_SMALL        =  200
    PROCESSING_PREVIEW  =  300

    MIN_DPI_LARGE       =  120
    DPI_MEDIUM          =   36
    DPI_SMALL           =   18

    SOURCE_DIR          = File.join(RAILS_ROOT, 'public', 'tmp_digital_files')
    DIGITAL_FILES_DIR   = File.join(RAILS_ROOT, 'public', 'digital_files')
    TMP_THUMBNAILS_DIR  = File.join(RAILS_ROOT, 'public', 'tmp_thumbnails')
    INGESTABLE_FORMATS  = [
                            {:format => 'tiff', :content_type => 'image/tiff'},
                            {:format => 'pdf', :content_type => 'application/pdf'},
                            {:format => 'jpeg', :content_type => 'image/jpeg'}
                          ]

  end
end

