# frozen_string_literal: true
# rubocop:disable Metrics/LineLength
require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

# This class establishes the actual email accounts.
class MailAccount
  include DataMapper::Resource

  property :id, Serial, key: true
  property :email, String, required: true, unique: true, length: 3..255
  property :realname, String, length: 1..255
  property :password, String, required: true, length: 255
  property :quota, Integer, required: true, min: 0, max: (2**63 - 1), default: 10_485_760 # 10MiB default
  property :quota_sieve_script, Integer, required: true, min: 0, max: (2**63 - 1), default: 10_240 # 10KiB default
  property :quota_sieve_actions, Integer, required: true, min: 0, default: 64
  property :quota_sieve_redirects, Integer, required: true, min: 0, default: 4
  property :receiving_enabled, Boolean, required: true, default: false
  property :created_at, Integer, min: 0, max: (2**63 - 1), default: 0
  property :updated_at, Integer, min: 0, max: (2**63 - 1), default: 0
  property :enabled, Boolean, default: false

  validates_format_of :email, as: :email_address
  validates_with_block :email do
    if MailAlias.first(address: email).nil? &&
       MailForwarding.first(address: email).nil?
      true
    else
      [false, 'Email is already taken']
    end
  end

  belongs_to :domain

  has n, :mail_sources, through: Resource, constraint: :skip
  has n, :mail_aliases, through: Resource, constraint: :skip

  before :create do
    self.created_at = Time.now.to_i
  end

  before :save do
    self.updated_at = Time.now.to_i
  end

  # @param options [Hash]
  # @return [Hash]
  def as_json(options = {})
    defaults = { exclude: [:password, :domain_id],
                 methods: [:quotausage,
                           :quotausage_rel,
                           :sieveusage,
                           :sieveusage_rel],
                 relationships: { domain: { only: [:id, :name] },
                                  mail_aliases: { only: [:id, :address] },
                                  mail_sources: { only: [:id, :address] } } }

    super(model_serialization_opts(defaults: defaults, options: options))
  end

  # @return [User]
  def owner
    domain.owner
  end

  # @return [Fixnum, nil]
  def quotausage
    return nil unless File.exist?(quotafile)
    IO.read(quotafile).match(%r{priv/quota/storage\n(.*)\n}m)[1].to_i
  end

  # @return [Fixnum]
  def quotausage_rel
    if quota.to_i.zero?
      0.0
    else
      (quotausage.to_i * 100 / quota).round(1)
    end
  end

  # @return [Fixnum, nil]
  def sieveusage
    return nil unless File.exist?(sievefile)
    File.size(sievefile)
  end

  # @return [Fixnum]
  def sieveusage_rel
    if quota_sieve_script.to_i.zero?
      0.0
    else
      (sieveusage.to_i * 100 / quota_sieve_script).round(1)
    end
  end

  private

  def quotafile
    settings = Sinatra::Application.settings
    [settings.mail_home,
     email.to_s.split('@')[1],
     email.to_s.split('@')[0],
     '.quotausage'].join('/')
  end

  def sievefile
    settings = Sinatra::Application.settings
    [settings.mail_home,
     email.to_s.split('@')[1],
     email.to_s.split('@')[0],
     settings.sieve_file].join('/')
  end
end
