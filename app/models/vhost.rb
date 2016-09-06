# frozen_string_literal: true
# rubocop:disable Metrics/LineLength
require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

# This class holds the virtual hosts.
class Vhost
  include DataMapper::Resource

  VHOST_TYPES = %w(vhost alias).freeze
  REDIRECT_TYPES = %w(none temporary permanent).freeze
  SUBDOMAIN_TYPES = %w(none www wildcard).freeze

  property :id, Serial, key: true
  property :fqdn, String, required: true, unique: true, length: 3..255
  property :type, String, length: 10, default: 'vhost'
  property :document_root, String, length: 0..255
  property :redirect_type, String, length: 15, default: 'none'
  property :redirect_target, String, length: 3..255
  property :quota, Integer, required: true, min: 0, max: (2**63 - 1), default: 104_857_600 # 100MiB default
  property :auto_subdomain, String, length: 15, default: 'none'
  property :php_enabled, Boolean, default: false
  property :apache_directives, Text, lazy: false
  property :nginx_directives, Text, lazy: false
  property :php_ini_settings, Text, lazy: false
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

  FQDN = %r{(?=^.{4,253}$)(^((?!-)[a-zA-Z0-9-]{1,63}(?<!-)\.)+[a-zA-Z]{2,63}$)}
  validates_format_of :fqdn, with: FQDN
  validates_format_of :redirect_target, as: :url, unless: ->(t) { t.redirect_type == 'none' }

  validates_within :type, set: VHOST_TYPES
  validates_within :redirect_type, set: REDIRECT_TYPES
  validates_within :auto_subdomain, set: SUBDOMAIN_TYPES

  belongs_to :user

  # alias vhosts
  has n, :aliases, self, child_key: :parent_id, constraint: :destroy
  belongs_to :parent, self, required: false

  has n, :sftp_users, constraint: :destroy
  has n, :shell_users, constraint: :destroy

  belongs_to :ipv4_address
  belongs_to :ipv6_address
  belongs_to :php_runtime, required: false

  before :create do
    self.created_at = Time.now.to_i
  end

  before :save do
    self.updated_at = Time.now.to_i
  end

  # @return [User]
  def owner
    user
  end
end
