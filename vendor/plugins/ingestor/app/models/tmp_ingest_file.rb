class TmpIngestFile < ActiveRecord::Base

  extend Ingestor::PrimaryKeyReset
  self.table_name = "wip.tmp_ingest_files"

  belongs_to :digital_file
  belongs_to :tmp_ingest_dir
  has_many :tmp_ingest_nodes

  validates_presence_of :tmp_ingest_dir_id

  named_scope :tiff_files, {
    :conditions => ["LOWER(line) LIKE ? OR LOWER(line) LIKE ?", '%.tif', '%.tiff'],
    :order => "original_filename"
  }
  named_scope :pdf_files, {
    :conditions => ["LOWER(line) LIKE ?", '%.pdf'],
    :order => "original_filename"
  }
  named_scope :for_lot, lambda { |lot_code| {
      :joins => :tmp_ingest_dir,
      :conditions => {:tmp_ingest_dirs => {:lot_code => lot_code} }
    }
  }

  def self.tmp_ingest_dir_ids_for_lot(lot_code)
    for_lot(lot_code).all(:select => "#{table_name}.id").map(&:id)
  end

  def self.destroy_lot(lot_code)
    delete_all(:id => tmp_ingest_dir_ids_for_lot(lot_code))
  end

  def self.nullify_lot(lot_code)
    update_all "original_object_id = NULL, digital_object_id = NULL, digital_file_id = NULL",
                {:id => tmp_ingest_dir_ids_for_lot(lot_code)}
  end

end

