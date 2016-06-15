# frozen_string_literal; false
require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

# This class holds the available PHP runtimes.
class PhpRuntime
  include DataMapper::Resource

  property :id, Serial, key: true
  property :name, String, required: true, unique_index: true, length: 10
  property :version, String, required: true, unique_index: true, length: 10
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
    User.first(name: 'admin')
  end
end
