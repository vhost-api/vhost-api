# frozen_string_literal: true
require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

# This class holds the DKIM author <-> key associations.
class DkimSigning
  include DataMapper::Resource

  property :id, Serial, key: true
  property :author, String, required: true, length: 255
  property :created_at, Integer, min: 0, max: (2**63 - 1), default: 0
  property :updated_at, Integer, min: 0, max: (2**63 - 1), default: 0
  property :enabled, Boolean, default: false

  belongs_to :dkim
  validates_presence_of :dkim, message: 'dkim_id must not be blank'

  before :create do
    self.created_at = Time.now.to_i
  end

  before :save do
    self.updated_at = Time.now.to_i
  end

  # @param options [Hash]
  # @return [Hash]
  def as_json(options = {})
    defaults = { exclude: [:dkim_id],
                 relationships: { dkim: { only: [:id] } } }

    super(model_serialization_opts(defaults: defaults, options: options))
  end

  # @return [User]
  def owner
    dkim.owner
  end
end
