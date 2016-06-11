require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

class MailSource
  include DataMapper::Resource
  
  property :id, Serial, key: true
  property :address, String, required: true, unique_index: true, length: 3..255
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
  has n, :mail_accounts, through: :mail_source_permissions, constraint: :destroy

  def as_json(options = {})
    defaults = { methods: [:allowed_from] }
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

  def allowed_from
    _return = []
    self.mail_source_permissions.each do |from|
      _return.push(MailAccount.get(from.mail_account_id).email.to_s)
    end
    _return
  end
  
  def owner
    Domain.get(self.domain_id).user_id
  end
end
