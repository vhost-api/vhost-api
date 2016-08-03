# frozen_string_literal: true
require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

# This class establishes the actual email accounts.
class MailAccount
  include DataMapper::Resource

  property :id, Serial, key: true
  property :email, String, required: true, unique: true, length: 3..255,
                           format: :email_address
  property :realname, String, required: false, length: 255
  property :password, String, required: true, length: 255
  property :quota, Integer, required: true, min: 0, max: (2**63 - 1),
                            default: 10_485_760 # 10MiB default
  property :quota_sieve_script, Integer, required: true, min: 0,
                                         max: (2**63 - 1),
                                         default: 1_048_576 # 1MiB default
  property :quota_sieve_actions, Integer, required: true, min: 0, default: 32
  property :quota_sieve_redirects, Integer, required: true, min: 0, default: 4
  property :receiving_enabled, Boolean, required: true, default: false
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

  has n, :mail_sources, through: Resource, constraint: :destroy
  has n, :mail_aliases, through: Resource, constraint: :destroy

  # @param options [Hash]
  # @return [Hash]
  def as_json(options = {})
    defaults = { exclude: [:password],
                 methods: [:quotausage,
                           :quotausage_rel,
                           :sieveusage,
                           :sieveusage_rel,
                           :customer] }
    options = defaults.merge(options)
    options[:only].delete(:password) if !options[:only].nil? &&
                                        options[:only].include?(:password)
    super(fix_options_override(options))
  end

  # @return [User]
  def owner
    domain.owner
  end

  # @return [Hash]
  def customer
    { id: domain.user.id, name: domain.user.name, login: domain.user.login }
  end

  # @return [Fixnum, nil]
  def quotausage
    return nil unless File.exist?(quotafile)
    IO.read(quotafile).match(%r{priv/quota/storage\n(.*)\n}m)[1].to_i
  end

  # @return [Fixnum]
  def quotausage_rel
    (quotausage.to_i * 100 / quota).round(1)
  end

  # @return [Fixnum, nil]
  def sieveusage
    return nil unless File.exist?(sievefile)
    File.size(sievefile)
  end

  # @return [Fixnum]
  def sieveusage_rel
    (sieveusage.to_i * 100 / quota_sieve_script).round(1)
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
