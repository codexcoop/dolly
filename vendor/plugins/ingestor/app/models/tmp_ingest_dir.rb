class TmpIngestDir < ActiveRecord::Base

  extend Ingestor::PrimaryKeyReset
  self.table_name = "wip.tmp_ingest_dirs"

  has_many      :tmp_ingest_files, :order => "original_filename"
  belongs_to    :original_object
  belongs_to    :digital_object, :class_name => 'DigitalObject', :foreign_key => 'tiff_digital_object_id'

  default_scope :order => 'dirname'
  named_scope   :unreferenced, { :conditions => {:original_object_id => nil} }
  named_scope   :with_new_original_object, { :conditions => {:original_object_is_new  => true} }
  named_scope   :for_lot, lambda { |lot_code| {:conditions => {:lot_code => lot_code} } }

  def self.destroy_lot(lot_code)
    delete_all(:lot_code => lot_code)
  end

  def self.nullify_lot(lot_code)
    update_all("tiff_digital_object_id = NULL, pdf_digital_object_id = NULL", {:lot_code => lot_code})
    update_all("original_object_id = NULL", {:original_object_is_new => true, :lot_code => lot_code})
  end

  def tmp_ingest_nodes
    TmpIngestNode.for_ingest_dir(self)
  end

  def tmp_ingest_files_attributes
    tmp_ingest_files.
    find( :all,
          :select => "id AS tmp_ingest_file_id, original_filename, digital_file_id",
          :order => 'original_filename' ).
    map(&:attributes)
  end

  def create_tmp_ingest_nodes_tree(&block)
    tmp_tree = TmpTree.new(tmp_ingest_files_attributes, &block)
    tmp_tree.generate_missing_nodes
    TmpIngestNode.create_tree_from_live_root(tmp_tree.live_root)
  end

  def import_tmp_nodes(node = digital_object.nodes.root, tmp_node = tmp_ingest_nodes.roots.first)
    raise ArgumentError, "node can't be nil" unless node
    raise ArgumentError, "tmp_node can't be nil" unless tmp_node

    if node.parent_id.nil? && tmp_node.is_root?
      node.update_attributes!(
        :description        => tmp_node.description,
        :digital_file_id    => tmp_node.digital_file_id
      )
    end

    tmp_node.update_attributes!(:node_id => node.id)

    tmp_node.children.each do |child_tmp_node|
      new_node = node.children.create!(
        :digital_object_id  => digital_object.id,
        :description        => child_tmp_node.description,
        :digital_file_id    => child_tmp_node.digital_file_id
      )

      import_tmp_nodes(new_node, child_tmp_node)
    end
  end

end

