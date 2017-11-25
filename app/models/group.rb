# frozen_string_literal: true

require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

# This class holds the groups.
class Group
  include DataMapper::Resource

  property :id, Serial, key: true
  property :name, String, unique: true, required: true, length: 3..255
  property :created_at, Integer, min: 0, max: (2**63 - 1), default: 0
  property :updated_at, Integer, min: 0, max: (2**63 - 1), default: 0
  property :enabled, Boolean, default: false

  before :create do
    self.created_at = Time.now.to_i
  end

  before :save do
    self.updated_at = Time.now.to_i
  end

  has n, :users, constraint: :protect

  # @return [User]
  def owner
    User.first(group: Group.first(name: 'admin'))
  end
end
