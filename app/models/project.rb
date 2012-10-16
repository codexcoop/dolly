class Project < ActiveRecord::Base
  include AutoconfigureEntity
  include Restrictable
  include Countable
  extend  Countable::ClassMethods
  include CommonValidations

  restrict_destroy_if_dependent :digital_collections

  before_validation :compute_uuid
  before_save :nullify_frivolous_dates

  # PAPERCLIP (configuration)
  has_attached_file :logo, :styles => { :medium => "150x150>", :thumb => "96x96>" },
                           :url => "/:attachment/projects/:id/:style/:filename"
  # IE FIX
  # Do google "validates_attachment_content_type ie"
  validates_attachment_content_type :logo,
                                    :content_type => ["image/jpeg", "image/png", "image/gif", "image/pjpeg", "image/x-png"],
                                    :if => Proc.new {|record| record.logo_file_name.present? }
  validates_attachment_size :logo,
                            :less_than => 2.megabytes,
                            :if => Proc.new {|record| record.logo_file_name.present? }

  # TODO: create a module for uuid computation
  def compute_uuid
    unless self.identifier
      random_uuid_seed = UUID.create_random
      self.identifier = UUID.create_sha1( self.title, random_uuid_seed).to_s
    end
  end

  belongs_to :institution, :counter_cache => true
  validates_presence_of :institution_id

  has_many :digital_collections

  @properties = [
    {
      :requirement=>"mandatory",
      :cardinality=>"one",
      :conditions=>{:vocabulary_id=>20, :property_id=>77},
      :name=>:status,
      :human_it => 'Stato'
    },
    {
      :requirement=>"optional",
      :cardinality=>"one",
      :conditions=>{:vocabulary_id=>11, :property_id=>71},
      :name=>:digitisation_process,
      :human_it => 'Processo di digitalizzazione'
    },
    {
      :requirement=>"optional",
      :cardinality=>"many",
      :conditions=>{:vocabulary_id=>12, :property_id=>72},
      :name=>:fundings,
      :human_it => 'Fonti di finanziamento'
    }
  ]

  define_associations_for_properties(@properties)

  validates_presence_of :title
  validates_length_of :title, :maximum => 255
  validates_uniqueness_of :title, :scope => :institution_id

  validates_presence_of :identifier
  validates_uniqueness_of :identifier

  belongs_to :user
  validates_presence_of :user_id

  validates_presence_of :description

  validates_presence_of :acronym
  validates_uniqueness_of :acronym, :scope => :institution_id

  # TODO: use the built in ":allow_blank" option
  validate_format_if_present :email, :with => :simple_email_regexp # see CommonRegexp module in /lib
  validate_format_if_present :url, :with => :simple_url_regexp # see CommonRegexp module in /lib

  validate :completion_date_greater_than_start_date, :if => :both_dates?

  def formatted_localized_completion_date
    case completion_date_format
      when 'Y'
        I18n.l(completion_date, :format => :only_year)
      when 'YM'
        I18n.l(completion_date, :format => :full_month_name_and_year)
      when 'YMD'
        I18n.l(completion_date, :format => :short)
      else
        I18n.l(completion_date, :format => :short)
    end
  end

  def formatted_localized_start_date
    case start_date_format
      when 'Y'
        I18n.l(start_date, :format => :only_year)
      when 'YM'
        I18n.l(start_date, :format => :full_month_name_and_year)
      when 'YMD'
        I18n.l(start_date)
      else
        I18n.l(start_date)
    end
  end

  private

  def nullify_frivolous_dates
    self.start_date = nil if self.start_date && self.start_date.year && self.start_date.year < 1970
    self.completion_date = nil if self.completion_date && self.completion_date.year && self.completion_date.year < 1970
  end

  def both_dates?
    completion_date && start_date
  end

  def completion_date_greater_than_start_date
    unless self.completion_date >= self.start_date
      errors.add :start_date, I18n.t(:prior_to_end_date, :scope => [:activerecord, :errors, :messages])
      errors.add :completion_date, I18n.t(:greater_than_start_date, :scope => [:activerecord, :errors, :messages])
    end
  end

end

