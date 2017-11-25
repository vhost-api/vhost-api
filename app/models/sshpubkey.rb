# frozen_string_literal: true

require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

# This class holds the ssh public keys.
class SshPubkey
  include DataMapper::Resource

  property :id, Serial, key: true
  property :pubkey, Text, required: true, lazy: false
  property :comment, Text, required: false, lazy: false
  property :created_at, Integer, min: 0, max: (2**63 - 1), default: 0,
                                 required: false
  property :updated_at, Integer, min: 0, max: (2**63 - 1), default: 0,
                                 required: false
  property :enabled, Boolean, default: false

  before :create do
    self.created_at = Time.now.to_i
  end

  before :save do
    self.updated_at = Time.now.to_i
  end

  belongs_to :user

  # @return [User]
  def owner
    user
  end
end
