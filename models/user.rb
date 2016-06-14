# frozen_string_literal: true
require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

# This class holds the users.
class User
  include DataMapper::Resource
  include BCrypt

  property :id, Serial, key: true
  property :name, String, required: true, unique_index: true, length: 3..255
  property :login, String, required: true, unique_index: true, length: 3..255
  property :password, BCryptHash, required: true, length: 255
  property :contact_email, String, required: false, length: 255
  property :quota_vhosts, Integer, required: true, min: 0, default: 1
  property :quota_vhost_storage, Integer, required: true, min: 0,
                                          max: (2**63 - 1),
                                          default: 104_857_600 # 100MiB default
  property :quota_alias_vhosts, Integer, required: true, min: 0, default: 1
  property :quota_databases, Integer, required: true, min: 0, default: 0
  property :quota_db_users, Integer, required: true, min: 0, default: 0
  property :quota_dns_zones, Integer, required: true, min: 0, default: 1
  property :quota_dns_zone_records, Integer, required: true, min: 0,
                                             default: 10
  property :quota_mail_domains, Integer, required: true, min: 0, default: 1
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

  has n, :vhosts, constraint: :protect
  has n, :alias_vhosts, constraint: :protect
  has n, :domains, constraint: :protect
  has n, :apikeys, constraint: :destroy
  has n, :ssh_pubkeys, constraint: :destroy

  def authenticate(attempted_password)
    # BCrypt automatically hashes the right side of ==
    # when comparing to self.password.
    if password == attempted_password
      true
    else
      false
    end
  end

  def owner
    User.get(name: 'admin').id
  end

  def owner_of?(element)
    element.owner == id
  end

  def admin?
    Group.get(group_id).name == 'admin'
  end
end
