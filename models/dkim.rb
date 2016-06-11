require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

class Dkim
  include DataMapper::Resource
  
  property :id, Serial, key: true
  property :selector, String, required: true, length: 63
  property :private_key, Text, required: false, lazy: false
  property :public_key, Text, required: false, lazy: false
  property :created_at, Integer, min: 0, max: (2**64 - 1), default: 0, required: false
  property :updated_at, Integer, min: 0, max: (2**64 - 1), default: 0, required: false
  property :enabled, Boolean, default: false
  
  before :create do
    self.created_at = Time.now.to_i
  end

  before :save do
    self.updated_at = Time.now.to_i
  end

  belongs_to :domain
  
  has n, :dkim_signings, constraint: :destroy
  
  def owner
    Domain.get(self.domain_id).user_id
  end
end
