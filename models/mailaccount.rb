# frozen_string_literal; false
require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

# This class establishes the actual email accounts.
class MailAccount
  include DataMapper::Resource

  property :id, Serial, key: true
  property :email, String, required: true, unique_index: true, length: 3..255,
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

  def as_json(options = {})
    defaults = { methods:
                 [:quotausage, :quotausage_rel, :sieveusage, :sieveusage_rel] }
    options = defaults.merge(options)

    # Fix options array if exclude/only parameters are given.
    if options.include?(:only) || options.include?(:exclude)
      only_props = Array(options[:only])
      excl_props = Array(options[:exclude])

      options[:methods].delete_if do |prop|
        if only_props.include? prop
          false
        else
          excl_props.include?(prop) ||
            !(only_props.empty? || only_props.include?(prop))
        end
      end
    end
    super(options)
  end

  def owner
    domain.owner
  end

  def quotausage
    settings = Sinatra::Application.settings
    filename = "#{settings.mail_home}/" \
               "#{email.to_s.split('@')[1]}/" \
               "#{email.to_s.split('@')[0]}/.quotausage"
    if File.exist?(filename)
      Integer(IO.read(filename).match(%r{priv/quota/storage\n(.*)\n}m)[1])
    else
      0
    end
  end

  def quotausage_rel
    (quotausage * 100 / quota).round(1)
  end

  def sieveusage
    settings = Sinatra::Application.settings
    filename = "#{settings.mail_home}/" \
               "#{email.to_s.split('@')[1]}/" \
               "#{email.to_s.split('@')[0]}/#{settings.sieve_file}"
    if File.exist?(filename)
      File.size(filename)
    else
      0
    end
  end

  def sieveusage_rel
    (sieveusage * 100 / quota_sieve_script).round(1)
  end
end
