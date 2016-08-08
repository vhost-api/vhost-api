# frozen_string_literal: true
require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

# This class holds the API keys.
class Apikey
  include DataMapper::Resource

  property :id, Serial, key: true
  property :apikey, String, required: true, unique: true, length: 128
  property :comment, String, required: false, length: 255
  property :created_at, Integer, min: 0, max: (2**63 - 1), default: 0,
                                 required: false
  property :updated_at, Integer, min: 0, max: (2**63 - 1), default: 0,
                                 required: false
  property :enabled, Boolean, default: false

  belongs_to :user

  before :create do
    self.created_at = Time.now.to_i
  end

  before :save do
    self.updated_at = Time.now.to_i
  end

  # @param options [Hash]
  # @return [Hash]
  def as_json(options = {})
    defaults = { exclude: [:user_id, :apikey],
                 relationships: { user: { only: [:id, :name, :login] } } }

    super(model_serialization_opts(defaults: defaults, options: options))
  end

  # @return [User]
  def owner
    user
  end

  # @return [Hash]
  def customer
    owner.as_json(only: [:id, :name, :login])
  end
end
