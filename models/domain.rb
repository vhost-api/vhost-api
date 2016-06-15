# frozen_string_literal; false
require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

# This class holds the domains.
class Domain
  include DataMapper::Resource

  property :id, Serial, key: true
  property :name, String, required: true, unique_index: true, length: 3..255
  property :mail_enabled, Boolean, default: false
  property :dns_enabled, Boolean, default: false
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

  belongs_to :user

  has n, :mail_accounts, constraint: :protect
  has n, :mail_aliases, constraint: :protect
  has n, :mail_sources, constraint: :protect
  has n, :dkims, constraint: :protect

  def as_json(options = {})
    defaults = { methods: [:customer] }
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
    user
  end

  def customer
    user.to_json(only: [:id, :name, :login])
  end
end
