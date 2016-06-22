# frozen_string_literal: true
require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

# This class holds the API keys.
class Apikey
  include DataMapper::Resource

  property :id, Serial, key: true
  property :apikey, String, required: true, length: 64
  property :access_level, Enum[:admin,
                               :admin_ro,
                               :user,
                               :user_ro,
                               :domain,
                               :domain_ro,
                               :vhost,
                               :vhost_ro,
                               :mailaccount,
                               :mailaccount_ro], required: true, default: :user
  property :valid_for, Integer, required: true, default: 0
  property :created_at, Integer, min: 0, max: (2**63 - 1), default: 0,
                                 required: false
  property :updated_at, Integer, min: 0, max: (2**63 - 1), default: 0,
                                 required: false
  property :comment, String, required: false, length: 255
  property :enabled, Boolean, default: false

  belongs_to :user

  before :create do
    self.created_at = Time.now.to_i
  end

  before :save do
    self.updated_at = Time.now.to_i
  end

  # @return [User]
  def owner
    user
  end
end
