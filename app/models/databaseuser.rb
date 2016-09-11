# frozen_string_literal: true
require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

# This class holds the database users.
class DatabaseUser
  include DataMapper::Resource

  property :id, Serial, key: true
  property :username, String, required: true, unique: true, length: 3..16
  property :password, String, required: true, length: 255
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

  has n, :databases, constraint: :protect

  def self.relationships
    {
      user: { only: [:id, :name, :login] },
      databases: { only: [:id, :name] }
    }
  end

  # @param options [Hash]
  # @return [Hash]
  def as_json(options = {})
    defaults = { exclude: [:password],
                 relationships: relationships }

    super(model_serialization_opts(defaults: defaults, options: options))
  end

  # @return [User]
  def owner
    user
  end
end
