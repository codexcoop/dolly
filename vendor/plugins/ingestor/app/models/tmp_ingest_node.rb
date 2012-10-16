class TmpIngestNode < ActiveRecord::Base

  extend Ingestor::PrimaryKeyReset
  self.table_name = "wip.tmp_ingest_nodes"

  has_ancestry :cache_depth => true
  belongs_to :digital_file
  belongs_to :node
  belongs_to :tmp_ingest_file

  validates_presence_of :tmp_ingest_file_id, :digital_file_id

  named_scope :for_lot, lambda { |lot_code| {
      :joins => {:tmp_ingest_file => :tmp_ingest_dir},
      :conditions => { :tmp_ingest_dirs => {:lot_code => lot_code} }
    }
  }
  named_scope :for_ingest_dir, lambda{|tmp_ingest_dir| {
      :conditions => { :tmp_ingest_file_id => tmp_ingest_dir.tmp_ingest_files.map(&:id) },
      :order => 'id'
    }
  }

  def self.tmp_ingest_dir_ids_for_lot(lot_code)
    for_lot(lot_code).all(:select => "#{table_name}.id").map(&:id)
  end

  def self.destroy_lot(lot_code)
    delete_all(:id => tmp_ingest_dir_ids_for_lot(lot_code))
  end

  def self.nullify_lot(lot_code)
    update_all "digital_file_id = NULL", {:id => tmp_ingest_dir_ids_for_lot(lot_code)}
  end

  def self.create_tree_from_live_root(live_node, record=nil)
    record =  if live_node.root?
                self.new(live_node.to_params)
              elsif record
                record.children.build(live_node.to_params)
              end
    return false unless record
    record.save!
    live_node.children.each do |live_child|
      create_tree_from_live_root(live_child, record) if record && record.valid?
    end
    record
  end

end

