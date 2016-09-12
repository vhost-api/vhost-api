# frozen_string_literal: true
require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

# This class holds the DKIM keys.
class Dkim
  include DataMapper::Resource

  property :id, Serial, key: true
  property :selector, String, required: true, length: 63
  property :private_key, Text, required: true, lazy: false
  property :public_key, Text, required: true, lazy: false
  property :created_at, Integer, min: 0, max: (2**63 - 1), default: 0
  property :updated_at, Integer, min: 0, max: (2**63 - 1), default: 0
  property :enabled, Boolean, default: false

  belongs_to :domain

  has n, :dkim_signings, constraint: :destroy

  before :create do
    self.created_at = Time.now.to_i
  end

  before :save do
    self.updated_at = Time.now.to_i
  end

  def self.relationship_options
    { domain: { only: [:id, :name] },
      dkim_signings: { only: [:id, :author] } }
  end

  # @param options [Hash]
  # @return [Hash]
  def as_json(options = {})
    defaults = { exclude: [:private_key, :domain_id],
                 relationships: relationship_options }

    super(model_serialization_opts(defaults: defaults, options: options))
  end

  # @return [User]
  def owner
    domain.owner
  end
end
