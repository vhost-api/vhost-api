# frozen_string_literal: true
require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'

# This class holds the users.
class User
  include DataMapper::Resource
  include BCrypt

  property :id, Serial, key: true
  property :name, String, required: true, length: 3..255
  property :login, String, required: true, unique: true, length: 3..255
  property :password, BCryptHash, required: true, length: 255
  property :contact_email, String, length: 255
  property :created_at, Integer, min: 0, max: (2**63 - 1), default: 0
  property :updated_at, Integer, min: 0, max: (2**63 - 1), default: 0
  property :enabled, Boolean, default: false

  validates_format_of :login, with: %r{^[a-zA-Z][a-zA-Z0-9\.\_\-]{2,253}$}
  validates_format_of :contact_email, as: :email_address

  before :create do
    self.created_at = Time.now.to_i
  end

  before :save do
    self.updated_at = Time.now.to_i
  end

  belongs_to :group

  has n, :packages, through: Resource, constraint: :skip

  has n, :ipv4_addresses, through: Resource, constraint: :skip
  has n, :ipv6_addresses, through: Resource, constraint: :skip

  has n, :vhosts, constraint: :destroy
  has n, :domains, constraint: :destroy
  has n, :databases, constraint: :destroy
  has n, :database_users, constraint: :destroy
  has n, :apikeys, constraint: :destroy
  has n, :ssh_pubkeys, constraint: :destroy

  # reseller relation
  has n, :customers, self, child_key: :reseller_id
  belongs_to :reseller, self, required: false

  # @return [Boolean]
  def authenticate(attempted_password)
    # BCrypt automatically hashes the right side of ==
    # when comparing to self.password.
    if password == attempted_password
      true
    else
      false
    end
  end

  # @param options [Hash]
  # @return [Hash]
  def as_json(options = {})
    defaults = { exclude: [:password, :group_id, :reseller_id],
                 relationships: { group: { only: [:id, :name] },
                                  packages: { only: [:id, :name] } } }
    defaults[:relationships][:reseller] = {
      only: [:id, :name, :login]
    } if reseller.is_a?(User)

    super(model_serialization_opts(defaults: defaults, options: options))
  end

  # @return [User]
  def owner
    if group.name == 'user' && !reseller.nil?
      reseller
    else
      User.first(group: Group.first(name: 'admin'))
    end
  end

  # @return [Boolean]
  def owner_of?(element)
    element.owner == self
  end

  # @return [Boolean]
  def admin?
    group == Group.first(name: 'admin')
  end

  # @return [Boolean]
  def reseller?
    group == Group.first(name: 'reseller')
  end
end
