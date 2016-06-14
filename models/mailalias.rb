# frozen_string_literal: true
require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

# This class holds the email aliases.
class MailAlias
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

  has n, :mail_alias_destinations, constraint: :destroy
  has n, :mail_accounts, through: :mail_alias_destinations, constraint: :destroy

  def as_json(options = {})
    defaults = { methods: [:destinations] }
    options = defaults.merge(options)

    # fix options array if exclude/only parameters are given
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

  def destinations
    dests = []
    mail_alias_destinations.each do |dest|
      dests.push(MailAccount.get(dest.mail_account_id).email.to_s)
    end
    dests
  end

  def owner
    Domain.get(domain_id).user_id
  end
end