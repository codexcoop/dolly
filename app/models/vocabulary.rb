class Vocabulary < ActiveRecord::Base
  include Restrictable
  include CustomCounterCachable

  restrict_destroy_if_dependent :terms

  before_create :compute_uuid

  def compute_uuid
    random_uuid_seed = UUID.create_random
    self.uuid = UUID.create_sha1( self.name, random_uuid_seed).to_s
  end

  has_many :terms

  belongs_to :user
  belongs_to :proposer, :class_name => 'User'

  has_many :properties
  has_many :entities, :through => :properties

  validates_uniqueness_of :name

  def self.perform_force_counter_cache_reset
    self.force_counter_cache_reset  :terms_count => :terms
  end

end

