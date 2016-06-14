# frozen_string_literal; false
require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

# This class holds the DKIM author <-> key associations.
class DkimSigning
  include DataMapper::Resource

  property :id, Serial, key: true
  property :author, String, required: true, key: true, length: 255
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

  belongs_to :dkim

  def owner
    Domain.get(Dkim.get(dkim_id).domain_id).user_id
  end
end
