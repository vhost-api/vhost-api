# frozen_string_literal: true
require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

# This class holds the email aliases.
class MailForwarding
  include DataMapper::Resource

  property :id, Serial, key: true
  property :address, String, required: true, unique: true, length: 3..255
  property :destinations, Text, lazy: false, required: true
  property :created_at, Integer, min: 0, max: (2**63 - 1), default: 0
  property :updated_at, Integer, min: 0, max: (2**63 - 1), default: 0
  property :enabled, Boolean, default: false

  validates_with_block :address do
    return true if check_email_address(address)
    [false, 'Address has an invalid format']
  end

  validates_with_block :address do
    if MailAccount.first(email: address).nil? &&
       MailAlias.first(address: address).nil?
      true
    else
      [false, 'Email is already taken']
    end
  end

  validates_with_block :destinations do
    err = [false, 'Invalid email within destinations']
    return err if destinations.nil?
    dests = destinations.split("\n")
    dests.each do |dest|
      return err unless check_email_address(dest)
    end
    true
  end

  belongs_to :domain

  before :create do
    self.created_at = Time.now.to_i
  end

  before :save do
    self.updated_at = Time.now.to_i
  end

  def self.relationships
    { domain: { only: [:id, :name] } }
  end

  # @param options [Hash]
  # @return [Hash]
  def as_json(options = {})
    defaults = { exclude: [:domain_id],
                 relationships: relationships }

    super(model_serialization_opts(defaults: defaults, options: options))
  end

  # @return [User]
  def owner
    domain.owner
  end

  private

  def check_email_address(email = nil)
    return false if email.nil?
    return false unless email.count('@') == 1
    return false unless email.length <= 254
    return false unless check_email_localpart(email)
    true
  end

  def check_email_localpart(email = nil)
    lpart = email.split('@')[0]
    # allow catchall
    return true if lpart.empty?
    return false unless lpart =~ %r{^[a-z0-9]+[a-z0-9._-]*$}
    return false if lpart =~ %r{\.\.{1,}}
    return false if %w(. _ -).include?(lpart[-1, 1])
    true
  end
end
