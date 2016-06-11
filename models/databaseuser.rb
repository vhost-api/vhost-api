require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

class DatabaseUser
  include DataMapper::Resource
  
  property :id, Serial, key: true
  property :username, String, required: true, unique_index: true, length: 3..16
  property :password, String, required: true, length: 255
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
  
  has n, :databases, constraint: :protect

  def owner
    self.user_id
  end
end
