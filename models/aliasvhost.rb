require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

class AliasVhost
  include DataMapper::Resource
  
  property :id, Serial, key: true
  property :fqdn, String, required: true, unique_index: true, length: 3..255
  property :auto_subdomain, Enum[ :none, :www, :wildcard ], required: false, default: :none
  property :redirect_type, Enum[ :temporary, :permanent ], required: true, default: :temporary
  property :destination, String, required: true
  property :ssl_enabled, Boolean, default: false
  property :ssl_crt, Text, lazy: false
  property :ssl_key, Text, lazy: false
  property :ssl_chain, Text, lazy: false
  property :created_at, Integer, min: 0, max: (2**64 - 1), default: 0, required: false
  property :updated_at, Integer, min: 0, max: (2**64 - 1), default: 0, required: false
  property :enabled, Boolean, default: false
  
  before :create do
    self.created_at = Time.now.to_i
  end

  before :save do
    self.updated_at = Time.now.to_i
  end
  
  belongs_to :user 
  
  belongs_to :ipv4_address
  belongs_to :ipv6_address
  
  def owner
    self.user_id
  end
end
