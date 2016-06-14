# frozen_string_literal: true
require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

# This class holds the available IPv4 addresses.
class Ipv6Address
  include DataMapper::Resource

  property :id, Serial, key: true
  property :address, IPAddress, required: true, unique_index: true
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

  has n, :vhosts, constraint: :protect

  def owner
    User.get(name: 'admin').id
  end
end
