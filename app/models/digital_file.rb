class DigitalFile < ActiveRecord::Base
  #FIXME: aggiungere validazioni, almeno user_id, original_filename, filename,...
  # position, original_position, digital_object_id, original_content_type, e
  # original_content_type dovrebbero essere presenti
  # verificare se non ci sono perché effettivamente c'era qualche motivo

  include CustomCounterCachable

  VARIANTS = {
    # NB: per ora nel METS si dà conto solo di large
    # :original => {:dir => "O", :usage => "image/master"},
    # :large    => {:dir => "L", :usage => "image/view"},
    # :medium   => {:dir => "M", :usage => "image/preview"},
    # :small    => {:dir => "S", :usage => "image/thumbnail"}
    :large    => {:dir => "L", :usage => "image/view"}
  }

  acts_as_list :scope => :digital_object_id

  serialize :large_technical_metadata, Hash

  belongs_to :digital_object, :counter_cache => true
  has_many  :nodes, :autosave => true, :dependent => :destroy

  before_create do |digital_file|
    digital_file.original_position = digital_file.position
  end

  def institution_id
    self.digital_object.institution_id if self.digital_object
  end

  attr_accessor :node_description

  def filesystem_path(*args)
    File.join( Rails.root, 'public', absolute_path(*args) )
  end

  def standard_path(options={})
    options.assert_required_keys(:variant)
    options.assert_valid_keys(:variant, :institution_id)

    institution_id = options[:institution_id] || self.institution_id

    if original_filename? && derivative_filename?
      File.join File.basename(DigitalObject::DIGITAL_FILES_DIR),
                institution_id.to_s,
                digital_object_id.to_s,
                options[:variant].to_s,
                options[:variant] == "O" ? original_filename : derivative_filename
    else
      ''
    end
  end

  def absolute_path(options={})
    if standard_path(options).present?
      File.join(File::SEPARATOR, standard_path(options))
    else
      ''
    end
  end

  def find_by_increment(increment)
    self.class.find :first,
                    :conditions => {:digital_object_id => self.digital_object_id,
                                    :position => self.position + increment }
  end

  def next_digital_file
    find_by_increment( 1 ) || self.digital_object.digital_files.find(:first)
  end

  def previous_digital_file
    find_by_increment( -1 ) || self.digital_object.digital_files.find(:last)
  end

  named_scope :outer_digital_objects_count, lambda{|*conditions|
    {
      :select => "digital_objects.id AS digital_object_id, COUNT(digital_files.id) AS count",
      :joins => "RIGHT OUTER JOIN digital_objects ON digital_files.digital_object_id = digital_objects.id",
      :conditions => merge_conditions(*conditions),
      :group => "digital_objects.id"
    }
  }

  named_scope :outer_digital_objects_content_type, lambda{|*conditions|
    {
      :select => "DISTINCT digital_objects.id AS digital_object_id, digital_files.original_content_type",
      :joins => "LEFT OUTER JOIN digital_objects ON digital_files.digital_object_id = digital_objects.id",
      :conditions => merge_conditions(*conditions)
    }
  }

end

