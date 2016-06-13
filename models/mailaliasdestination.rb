# frozen_string_literal: true
require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

# This class holds the associated destinations for each email alias.
class MailAliasDestination
  include DataMapper::Resource

  belongs_to :mail_account, key: true
  belongs_to :mail_alias, key: true
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

  def owner
    Domain.get(MailAccount.get(mail_account_id).domain_id).user_id
  end
end
