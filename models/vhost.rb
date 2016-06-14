# frozen_string_literal: true
require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

# This class holds the virtual hosts.
class Vhost
  include DataMapper::Resource

  property :id, Serial, key: true
  property :fqdn, String, required: true, unique_index: true, length: 3..255
  property :quota_vhost_storage, Integer, required: true, min: 0,
                                          max: (2**63 - 1),
                                          default: 104_857_600 # 100MiB default
  property :auto_subdomain, Enum[:none, :www, :wildcard], required: false,
                                                          default: :none
  property :php_enabled, Boolean, default: false
  property :ssl_enabled, Boolean, default: false
  property :ssl_crt, Text, lazy: false
  property :ssl_key, Text, lazy: false
  property :ssl_chain, Text, lazy: false
  property :os_uid, String, required: true, default: 'nobody' # 99 -- nobody
  property :os_gid, String, required: true, default: 'nobody' # 99 -- nobody
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

  has n, :sftp_users, constraint: :destroy
  has n, :shell_users, constraint: :destroy

  belongs_to :ipv4_address
  belongs_to :ipv6_address
  belongs_to :php_runtime

  def owner
    user_id
  end
end
