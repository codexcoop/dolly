class Role < ActiveRecord::Base
  include Restrictable

  # TODO: add a counter cache for users
  before_destroy 'restrict_if_dependent(:users)'  # use single quotes (not double quotes), so it becomes
                                                  # an inline eval method, and will be evaluated only
                                                  # when the callback is triggered


  validates_presence_of :name
  validates_uniqueness_of :name

  validates_presence_of :permission_level
  validates_uniqueness_of :permission_level

  has_many :users
end

