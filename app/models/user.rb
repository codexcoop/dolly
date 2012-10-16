class User < ActiveRecord::Base
  include Comparable
  include Restrictable
  include CommonValidations

  acts_as_authentic do |c|
    c.logged_in_timeout 4.hours
  end

  restrict_destroy_if_dependent :digital_collections,
                                :digital_objects,
                                :original_objects,
                                :digital_files,
                                :projects,
                                :terms

  [ :digital_collections, :digital_objects, :original_objects,
    :digital_files, :projects, :terms].each do |plural_model_name|
    plural_model_name_sym = plural_model_name.to_sym
    has_many plural_model_name.to_sym
  end

  belongs_to :institution
  validates_presence_of :institution_id

  belongs_to :role
  validates_presence_of :role_id

  validates_presence_of :first_name
  validates_presence_of :last_name

  # TODO: use the built in ":allow_blank" option
  validate_format_if_present :email, :with => :simple_email_regexp # see CommonRegexp module in /lib

  def full_name
    "#{first_name} #{last_name}"
  end

  def permission_level
    self.role.permission_level
  end

  def <=>(other_user_or_role)
    self.permission_level <=> other_user_or_role.permission_level
  end

  # Scopes
  named_scope :list,
              :joins => [ :institution, :role ],
              :select => "users.id, users.first_name, users.last_name, users.login, users.institution_id, users.role_id, institutions.name as institution_name, roles.name as role_name"

end

