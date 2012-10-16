module Ingestor
  module ModelExt

    def self.extend_models
      extend_digital_object
      extend_original_object
      extend_digital_file
      extend_node
    end

    def self.extend_digital_object
      DigitalObject.class_eval do
        extend PrimaryKeyReset
        include DirIngestSupport
        has_one :tmp_ingest_dir, :foreign_key => "tiff_digital_object_id"
        named_scope :created_by_ingest_for_lot, lambda { |lot_code|
          {
            :joins => :tmp_ingest_dir,
            :conditions => {
              :tmp_ingest_dirs => {
                :digital_object_is_new => true,
                :lot_code => lot_code
              }
            }
          }
        }

        def self.destroy_ingested_for_lot(lot_code)
          delete_all(:id => DigitalObject.created_by_ingest_for_lot(lot_code).map(&:id))
        end
      end
    end

    def self.extend_original_object
      OriginalObject.class_eval do
        extend PrimaryKeyReset
        has_one :tmp_ingest_dir

        named_scope :created_by_ingest_for_lot, lambda { |lot_code|
          {
            :joins => :tmp_ingest_dir,
            :conditions => {
              :tmp_ingest_dirs => {
                :original_object_is_new => true,
                :lot_code => lot_code
              }
            }
          }
        }

        def self.destroy_ingested_for_lot(lot_code)
          # OPTIMIZE: due volte map ???
          delete_all(:id => OriginalObject.created_by_ingest_for_lot(lot_code).map(&:id).map(&:id))
        end
      end
    end

    def self.extend_digital_file
      DigitalFile.class_eval do
        extend PrimaryKeyReset
        has_one :tmp_ingest_file
        has_many :tmp_ingest_nodes
        named_scope :created_by_ingest, { :joins => :tmp_ingest_file }

        def self.destroy_ingested_for_lot(lot_code)
          delete_all(:digital_object_id => DigitalObject.created_by_ingest_for_lot(lot_code).map(&:id))
        end
      end
    end

    def self.extend_node
      Node.class_eval do
        extend PrimaryKeyReset

        def self.destroy_ingested_for_lot(lot_code)
          delete_all(:digital_object_id => DigitalObject.created_by_ingest_for_lot(lot_code).map(&:id))
        end
      end
    end

  end
end

