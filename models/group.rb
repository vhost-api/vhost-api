require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

class Group
  include DataMapper::Resource
  
  property :id, Serial, key: true
  property :name, String, unique_index: true, required: true, length: 3..255
  property :created_at, Integer, min: 0, max: (2**64 - 1), default: 0, required: false
  property :updated_at, Integer, min: 0, max: (2**64 - 1), default: 0, required: false
  property :enabled, Boolean, default: false
  
  before :create do
    self.created_at = Time.now.to_i
  end

  before :save do
    self.updated_at = Time.now.to_i
  end
  
  has n, :users, constraint: :protect
  
  def owner
    User.get(name: 'admin').id
  end
end
