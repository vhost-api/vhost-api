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
  property :created_at, Integer, min: 0, max: (2**63 - 1), default: 0
  property :updated_at, Integer, min: 0, max: (2**63 - 1), default: 0
  property :enabled, Boolean, default: false

  FQDN = %r{(?=^.{4,253}$)(^((?!-)[a-zA-Z0-9-]{1,63}(?<!-)\.)+[a-zA-Z]{2,63}$)}
  validates_format_of :name, with: FQDN

  belongs_to :user

  has n, :mail_accounts, constraint: :destroy
  has n, :mail_forwardings, constraint: :destroy
  has n, :mail_aliases, constraint: :destroy
  has n, :mail_sources, constraint: :destroy
  has n, :dkims, constraint: :destroy

  before :create do
    self.created_at = Time.now.to_i
  end

  before :save do
    self.updated_at = Time.now.to_i
  end

  def self.relationships
    { user: { only: [:id, :name, :login] } }
  end

  # @param options [Hash]
  # @return [Hash]
  def as_json(options = {})
    defaults = { exclude: [:user_id],
                 relationships: relationships }

    super(model_serialization_opts(defaults: defaults, options: options))
  end

  # @return [User]
  def owner
    user
  end
end
