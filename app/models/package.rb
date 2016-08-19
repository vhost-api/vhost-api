# frozen_string_literal: true
# rubocop:disable Metrics/LineLength
require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

# This class holds the users.
class Package
  include DataMapper::Resource

  property :id, Serial, key: true
  property :name, String, required: true, length: 3..255
  property :price_unit, Integer, required: true, min: 0, max: (2**63 - 1)
  property :quota_apikeys, Integer, required: true, min: 0, default: 3
  property :quota_custom_packages, Integer, required: true, min: 0, default: 0
  property :quota_ssh_pubkeys, Integer, required: true, min: 0, default: 2
  property :quota_customers, Integer, required: true, min: 0, default: 0
  property :quota_vhosts, Integer, required: true, min: 0, default: 1
  property :quota_vhost_storage, Integer, required: true, min: 0, max: (2**63 - 1), default: 104_857_600 # 100MiB default
  property :quota_databases, Integer, required: true, min: 0, default: 0
  property :quota_database_users, Integer, required: true, min: 0, default: 0
  property :quota_dns_zones, Integer, required: true, min: 0, default: 1
  property :quota_dns_records, Integer, required: true, min: 0, default: 10
  property :quota_domains, Integer, required: true, min: 0, default: 1
  property :quota_mail_accounts, Integer, required: true, min: 0, default: 5
  property :quota_mail_aliases, Integer, required: true, min: 0, default: 10
  property :quota_mail_sources, Integer, required: true, min: 0, default: 10
  property :quota_mail_storage, Integer, required: true, min: 0, max: (2**63 - 1), default: 104_857_600 # 100MiB default
  property :quota_sftp_users, Integer, required: true, min: 0, default: 1
  property :quota_shell_users, Integer, required: true, min: 0, default: 0
  property :created_at, Integer, min: 0, max: (2**63 - 1), default: 0
  property :updated_at, Integer, min: 0, max: (2**63 - 1), default: 0
  property :enabled, Boolean, default: true

  before :create do
    self.created_at = Time.now.to_i
  end

  before :save do
    self.updated_at = Time.now.to_i
  end

  belongs_to :user
  has n, :users, through: Resource, constraint: :skip

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
end
