# frozen_string_literal: true
require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

# This class holds the email aliases.
class MailAlias
  include DataMapper::Resource

  property :id, Serial, key: true
  property :address, String, required: true, unique: true, length: 3..255
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

  belongs_to :domain

  has n, :mail_accounts, through: Resource, constraint: :destroy

  # @param options [Hash]
  # @return [Hash]
  def as_json(options = {})
    defaults = { exclude: [:domain_id],
                 relationships: { domain: { only: [:id, :name] },
                                  mail_accounts: { only: [:id, :email] } } }

    super(model_serialization_opts(defaults: defaults, options: options))
  end

  # @return [User]
  def owner
    domain.owner
  end
end
