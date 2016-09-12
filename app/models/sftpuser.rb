# frozen_string_literal: true
require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

# This class holds the sftp users.
class SftpUser
  include DataMapper::Resource

  property :id, Serial, key: true
  property :username, String, required: true, unique: true, length: 3..255
  property :password, String, required: true, length: 255
  property :homedir, String, required: true, length: 255, default: '/bin/false'
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

  belongs_to :vhost

  def self.relationship_options
    { vhost: { only: [:id, :fqdn] } }
  end

  # @param options [Hash]
  # @return [Hash]
  def as_json(options = {})
    defaults = { exclude: [:password],
                 relationships: relationship_options }

    super(model_serialization_opts(defaults: defaults, options: options))
  end

  # @return [User]
  def owner
    vhost.owner
  end
end
