# frozen_string_literal: true
require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

# This class holds the email sources (outgoing addresses).
class MailSource
  include DataMapper::Resource

  property :id, Serial, key: true
  property :address, String, required: true, unique_index: true, length: 3..255
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

  belongs_to :domain

  has n, :mail_accounts, through: Resource, constraint: :destroy

  # @param options [Hash]
  # @return [Hash]
  def as_json(options = {})
    defaults = { methods: [:allowed_from] }
    options = defaults.merge(options)
    super(fix_options_override(options))
  end

  # @return [Array(MailAccount)]
  def allowed_from
    allowed_senders = []
    mail_accounts.each do |acc|
      allowed_senders.push(acc.email.to_s)
    end
    allowed_senders
  end

  # @return [User]
  def owner
    domain.owner
  end
end
