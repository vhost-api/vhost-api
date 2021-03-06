# frozen_string_literal: true

require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

# This class holds the databases.
class Database
  include DataMapper::Resource

  property :id, Serial, key: true
  property :name, String, required: true, unique: true, length: 3..64
  property :type, Enum[:mysql], required: true, default: :mysql
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

  belongs_to :database_user
  belongs_to :user

  has n, :database_users, constraint: :protect

  # @param options [Hash]
  # @return [Hash]
  def as_json(options = {})
    defaults = { relationships: { user: { only: %i[id name login] },
                                  database_user: { only: %i[id username] } } }

    super(model_serialization_opts(defaults: defaults, options: options))
  end

  # @return [User]
  def owner
    user
  end
end
