# frozen_string_literal: true
require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

# This class holds the shell users.
class ShellUser
  include DataMapper::Resource

  property :id, Serial, key: true
  property :username, String, required: true, unique_index: true, length: 5..255
  property :password, String, required: true, length: 255
  property :uid, Integer, required: true, min: 0, default: 99 # 99 -- nobody
  property :gid, Integer, required: true, min: 0, default: 99 # 99 -- nobody
  property :created_at, Integer, min: 0, max: (2**64 - 1), default: 0,
                                 required: false
  property :updated_at, Integer, min: 0, max: (2**64 - 1), default: 0,
                                 required: false
  property :enabled, Boolean, default: false

  before :create do
    self.created_at = Time.now.to_i
  end

  before :save do
    self.updated_at = Time.now.to_i
  end

  belongs_to :vhost
  belongs_to :shell

  def owner
    Vhost.get(vhost_id).user_id
  end
end
