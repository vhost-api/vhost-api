# frozen_string_literal: true
require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

# This class holds the domains.
class Domain
  include DataMapper::Resource

  property :id, Serial, key: true
  property :name, String, required: true, unique: true, length: 3..255
  property :mail_enabled, Boolean, default: false
  property :dns_enabled, Boolean, default: false
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

  has n, :mail_accounts, constraint: :protect
  has n, :mail_aliases, constraint: :protect
  has n, :mail_sources, constraint: :protect
  has n, :dkims, constraint: :protect

  # @param options [Hash]
  # @return [Hash]
  def as_json(options = {})
    defaults = { exclude: [:user_id],
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
