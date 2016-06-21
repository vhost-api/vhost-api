require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

# This class holds the virtual hosts.
class Vhost
  include DataMapper::Resource

  property :id, Serial, key: true
  property :fqdn, String, required: true, unique_index: true, length: 3..255
  property :type, Enum[:vhost, :alias], default: :vhost
  property :document_root, String, length: 0..255
  property :redirect_type, Enum[:none, :temporary, :permanent], default: :none
  property :redirect_target, Text, lazy: false
  property :quota_vhost_storage, Integer, required: true, min: 0,
                                          max: (2**63 - 1),
                                          default: 104_857_600 # 100MiB default
  property :auto_subdomain, Enum[:none, :www, :wildcard], default: :none
  property :php_enabled, Boolean, default: false
  property :ssl_enabled, Boolean, default: false
  property :ssl_letsencrypt, Boolean, default: false
  property :force_ssl, Boolean, default: false
  property :ssl_crt, Text, lazy: false
  property :ssl_key, Text, lazy: false
  property :ssl_chain, Text, lazy: false
  property :os_uid, String, default: 'nobody' # 99 -- nobody
  property :os_gid, String, default: 'nobody' # 99 -- nobody
  property :created_at, Integer, min: 0, max: (2**63 - 1), default: 0
  property :updated_at, Integer, min: 0, max: (2**63 - 1), default: 0
  property :enabled, Boolean, default: false

  before :create do
    self.created_at = Time.now.to_i
  end

  before :save do
    self.updated_at = Time.now.to_i
  end

  belongs_to :user

  # alias vhosts
  has n, :aliases, self, child_key: :parent_id
  belongs_to :parent, self, required: false

  has n, :sftp_users, constraint: :destroy
  has n, :shell_users, constraint: :destroy

  belongs_to :ipv4_address
  belongs_to :ipv6_address
  belongs_to :php_runtime, required: false

  # @return [User]
  def owner
    user
  end
end
