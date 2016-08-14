# frozen_string_literal: true
require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

# This class holds the users.
class User
  include DataMapper::Resource
  include BCrypt

  property :id, Serial, key: true
  property :name, String, required: true, length: 3..255
  property :login, String, required: true, unique: true, length: 3..255
  property :password, BCryptHash, required: true, length: 255
  property :contact_email, String, required: false, length: 255
  property :quota_apikeys, Integer, required: true, min: 0, default: 3
  property :quota_ssh_pubkeys, Integer, required: true, min: 0, default: 10
  property :quota_customers, Integer, required: true, min: 0, default: 0
  property :quota_vhosts, Integer, required: true, min: 0, default: 1
  property :quota_vhost_storage, Integer, required: true, min: 0,
                                          max: (2**63 - 1),
                                          default: 104_857_600 # 100MiB default
  property :quota_databases, Integer, required: true, min: 0, default: 0
  property :quota_database_users, Integer, required: true, min: 0, default: 0
  property :quota_dns_zones, Integer, required: true, min: 0, default: 1
  property :quota_dns_records, Integer, required: true, min: 0,
                                        default: 10
  property :quota_domains, Integer, required: true, min: 0, default: 1
  property :quota_mail_accounts, Integer, required: true, min: 0, default: 5
  property :quota_mail_aliases, Integer, required: true, min: 0, default: 10
  property :quota_mail_sources, Integer, required: true, min: 0, default: 10
  property :quota_mail_storage, Integer, required: true, min: 0,
                                         max: (2**63 - 1),
                                         default: 104_857_600 # 100MiB default
  property :quota_sftp_users, Integer, required: true, min: 0, default: 1
  property :quota_shell_users, Integer, required: true, min: 0, default: 0
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

  belongs_to :group

  has n, :ipv4_addresses, through: Resource, constraint: :skip
  has n, :ipv6_addresses, through: Resource, constraint: :skip

  has n, :vhosts, constraint: :destroy
  has n, :domains, constraint: :destroy
  has n, :databases, constraint: :destroy
  has n, :database_users, constraint: :destroy
  has n, :apikeys, constraint: :destroy
  has n, :ssh_pubkeys, constraint: :destroy

  # reseller relation
  has n, :customers, self, child_key: :reseller_id
  belongs_to :reseller, self, required: false

  # @return [Boolean]
  def authenticate(attempted_password)
    # BCrypt automatically hashes the right side of ==
    # when comparing to self.password.
    if password == attempted_password
      true
    else
      false
    end
  end

  # @param options [Hash]
  # @return [Hash]
  def as_json(options = {})
    defaults = if reseller.is_a?(User)
                 { exclude: [:password, :group_id, :reseller_id],
                   relationships: { group: { only: [:id, :name] },
                                    reseller: { only: [:id, :name, :login] } } }
               else
                 { exclude: [:password, :group_id, :reseller_id],
                   relationships: { group: { only: [:id, :name] } } }
               end

    super(model_serialization_opts(defaults: defaults, options: options))
  end

  # @return [User]
  def owner
    if group.name == 'user' && !reseller.nil?
      reseller
    else
      User.first(login: 'admin')
    end
  end

  # @return [Boolean]
  def owner_of?(element)
    element.owner == self
  end

  # @return [Boolean]
  def admin?
    group.name == 'admin'
  end

  # @return [Boolean]
  def reseller?
    group.name == 'reseller'
  end
end
