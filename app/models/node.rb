class Node < ActiveRecord::Base

  include ActiveSupport

  belongs_to :digital_object
  belongs_to :digital_file

  # TODO: write separate callbacks
  #  before_validation :set_digital_object_id
  #  before_validation :set_parent_id
  before_validation :set_digital_object_id_and_parent_id

  validates_presence_of :description
  validate :presence_of_description_in_parent

  acts_as_list :scope => :parent_id
  acts_as_tree :order => "position"

  def move_globally(options={})
    options.assert_valid_keys :new_parent_id, :new_position

    if self.parent_id.to_s != options[:new_parent_id].to_s
      self.move_to_new_parent :new_parent_id => options[:new_parent_id], :position => options[:new_position]
    elsif self.position != options[:new_position].to_i
      self.move_multiple :new_position => options[:new_position]
    end
  end

  # when only position changes, the result from jstree is different when
  # position descrease (starts counting from zero) and when position grows
  # (starts counting from one)
  def move_multiple(options={})
    options.assert_valid_keys :new_position

    if options[:new_position].to_i < self.position # jstree starts from zero
      self.transaction { self.insert_at(options[:new_position].to_i+1) }
    else # jstree starts from one
      self.transaction { self.insert_at(options[:new_position].to_i) }
    end

  end

  # when parent changes, jstree always starts counting from zero
  def move_to_new_parent(options={})
    options.assert_valid_keys :new_parent_id, :position
    options.assert_required_keys :new_parent_id

    self.transaction do
      self.remove_from_list
      self.class.find(options[:new_parent_id]).children << self
      self.insert_at(options[:position].to_i+1) # jstree always starts from zero
    end
  end

  def set_digital_object_id_and_parent_id
    return if parent_id.nil? || digital_object_id.present?
    self.digital_object_id = parent.digital_object_id
    # OPTIMIZE: forse le cose si semplificano passando a ancestry
  end

  # attenzione questo callback funziona solo con create, non con build
  # after_initialize è comunque sconsigliabile perché scatena una query ogni volta che un oggetto viene istanziato
  #  def after_initialize
  #    self.digital_object_id = self.parent.digital_object_id if self.parent
  #  end

  def presence_of_description_in_parent
    if self.parent and self.parent.description.blank?
      errors.add(:parent_id, "The parent of a node must have a description")
    end
  end

  attr_reader   :family
  attr_accessor :memoized_children
  attr_writer   :sub_tree

  def initialize_family
    @family = self.class.find(:all,
                              :conditions => {:digital_object_id => self.digital_object_id},
#                              :include => [:digital_file],
                              :order => "nodes.parent_id, nodes.position")
  end

  def descendants
    initialize_family
    memoize_descendants(self.family)
  end

  def sub_tree
    initialize_family
    memoize_sub_tree(self.family)
    self
  end

  def tree
    self.root.sub_tree
    root
  end

  def to_jstree_hash
    {
      :data => self.description,
      :attr => {
                 :id => "node-#{self.id}",
                 'data-is-toc' => self.parent.nil?,
                 'data-digital-file-id' => self.digital_file_id,
                 'data-page-number' => self.digital_file.try(:position)
      }
    }
  end

  def descendants_to_jstree_hash
    initialize_family
    memoize_descendants_to_jstree_hash(self.family)
  end

  def memoize_children(preset_family)
    preset_family.select{|node| node.parent_id == self.id}
  end

  # recursive, one query per call
  def memoize_descendants(preset_family)
    memoize_children(preset_family).collect { |node|
      [node, node.send(__method__, preset_family)]
    }.flatten.compact
  end

  def memoize_sub_tree(preset_family)
    children = memoize_children(preset_family)

    if children.any?
      self.memoized_children = children
      self.memoized_children.each{ |node| node.send(__method__, preset_family) }
    end
    self.memoized_children
  end

  def memoize_descendants_to_jstree_hash(preset_family)
    node_hash = {}
    self.memoized_children = memoize_children(preset_family)

    node_hash.update( self.to_jstree_hash )
    if self.memoized_children.any?
      node_hash[:children] = self.memoized_children.collect do |child|
        child.send(__method__, preset_family) # __method__ returns the name of the current method (recursive call)
      end
    end
    node_hash
  end

  # Gives the descendants+self organized in a nested hash
  # every node is a key of a hash, and a value is
  # either an empty hash (for node with no children), or a hash in which
  # its children are the keys, and the values are hashes with
  # the same structure, and so on, recursively.
  # It is a stand-alone method.
  # It does only one query for the entire sub_tree.
  def arrange_sub_tree(node=self, family=initialize_family)
    OrderedHash.new.tap do |hash|
      hash[node]  = OrderedHash.new{|h,k| h[k] = {}}
      family.select{|relative| relative.parent_id == node.id }.each do |child|
         hash[node].merge!(node.send(__method__, child, family))
      end
    end
  end

  # Gives the arranged sub tree of the root of the current node.
  # Two total queries (one for the root, and one for the sub tree).
  # See also the method arrange_sub_tree.
  def arrange_tree
    root.arrange_sub_tree
  end

  # SAMPLE JSON OBJECT JSTREE-COMPATIBLE
  #
  # "data" : [
  #   {
  #     "data" : "A node",
  #     "attr" : { id : "node-1" },
  #     // `state` and `children` are only used for NON-leaf nodes
  #     //"state": "open",
  #     "children" : [
  #       { "data" : "Child node",
  #         "attr" : { id : "node-2" },
  #       },
  #       { "data" : "Child node",
  #         "attr" : { id : "node-3" },
  #       }
  #     ]
  #   },
  #   {
  #     "data" : "Another node",
  #     "attr" : { id : "node-4" },
  #     // `state` and `children` are only used for NON-leaf nodes
  #     //"state": "open",
  #     "children" : [
  #       { "data" : "Child node",
  #         "attr" : { id : "node-5" },
  #       },
  #       { "data" : "Child node",
  #         "attr" : { id : "node-6" },
  #       }
  #     ]
  #   }
  # ]

end

