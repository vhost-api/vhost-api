require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

class MailAccount
  include DataMapper::Resource
  
  property :id, Serial, key: true
  property :email, String, required: true, unique_index: true, length: 3..255, format: :email_address
  property :realname, String, required: false, length: 255
  property :password, String, required: true, length: 255
  property :quota, Integer, required: true, min: 0, max: (2**64 - 1), default: 10485760   # unsigned bigint, 10MiB default
  property :quota_sieve_script, Integer, required: true, min: 0, max: (2**64 - 1), default: 1048576   # unsigned bigint, 1MiB default
  property :quota_sieve_actions, Integer, required: true, min: 0, default: 32
  property :quota_sieve_redirects, Integer, required: true, min: 0, default: 4
  property :receiving_enabled, Boolean, required: true, default: false
  property :created_at, Integer, min: 0, max: (2**64 - 1), default: 0, required: false
  property :updated_at, Integer, min: 0, max: (2**64 - 1), default: 0, required: false
  property :enabled, Boolean, default: false
  
  before :create do
    self.created_at = Time.now.to_i
  end

  before :save do
    self.updated_at = Time.now.to_i
  end
  
  belongs_to :domain 
  
  has n, :mail_source_permissions, constraint: :destroy
  has n, :mail_sources, through: :mail_source_permissions, constraint: :destroy
  
  has n, :mail_alias_destinations, constraint: :destroy
  has n, :mail_aliases, through: :mail_alias_destinations, constraint: :destroy

  def as_json(options = {})
    defaults = { methods: [:quotausage, :quotausage_rel, :sieveusage, :sieveusage_rel] }
    options = defaults.merge(options)

    # fix options array if exclude/only parameters are given
    if options.include? :only or options.include? :exclude
      only_props = Array(options[:only])
      excl_props = Array(options[:exclude])

      options[:methods].delete_if do |prop|
        if only_props.include? prop
          false
        else
          excl_props.include?(prop) || !(only_props.empty? || only_props.include?(prop))
        end
      end
    end
    super(options)
  end

  def owner
    Domain.get(self.domain_id).user_id
  end

  def quotausage
    filename = "#{$appconfig[:mail_home]}/" \
               "#{self.email.to_s.split('@')[1]}/" \
               "#{self.email.to_s.split('@')[0]}/.quotausage"
    if File.exist?(filename)
      Integer(IO.read(filename).match(/priv\/quota\/storage\n(.*)\n/m)[1])
    else
      0
    end
  end

  def quotausage_rel
    (self.quotausage*100/self.quota).round(1)
  end

  def sieveusage
    filename = "#{$appconfig[:mail_home]}/" \
               "#{self.email.to_s.split('@')[1]}/" \
               "#{self.email.to_s.split('@')[0]}/#{$appconfig[:sieve_file]}"
    if File.exist?(filename)
      File.size(filename)
    else
      0
    end
  end

  def sieveusage_rel
    (self.sieveusage*100/self.quota_sieve_script).round(1)
  end
end
