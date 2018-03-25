# frozen_string_literal: true

require 'yaml'

lp = File.expand_path(__dir__)

@environment = ENV['RACK_ENV'] || 'development'
# rubocop:disable Security/YAMLLoad
@dbconfig = YAML.load(File.read("#{lp}/config/database.yml"))[@environment]
# rubocop:enable Security/YAMLLoad

require 'bundler/setup'

require 'fileutils'
require 'tempfile'
require 'data_mapper'
require 'dm-migrations'
require 'dm-constraints'
require 'dm-timestamps'
require 'dm-serializer'
require 'securerandom'

case @dbconfig[:db_adapter].upcase
when 'POSTGRES'
  require 'dm-postgres-adapter'
  @dbconfig[:db_port] = 5432 if @dbconfig[:db_port].nil?
when 'MYSQL'
  require 'dm-mysql-adapter'
  @dbconfig[:db_port] = 3306 if @dbconfig[:db_port].nil?
end

require 'bcrypt'
require 'sshkey'

# monkey patch to fix deprecation warning
# rubocop:disable Style/Documentation, Style/RaiseArgs, Metrics/LineLength
# rubocop:disable Style/CaseEquality
module DataObjects
  module Pooling
    class Pool
      attr_reader :available
      attr_reader :used

      def initialize(max_size, resource, args)
        raise ArgumentError.new("+max_size+ should be an Integer but was #{max_size.inspect}") unless Integer === max_size
        raise ArgumentError.new("+resource+ should be a Class but was #{resource.inspect}") unless Class === resource

        @max_size = max_size
        @resource = resource
        @args = args

        @available = []
        @used      = {}
        DataObjects::Pooling.append_pool(self)
      end
    end
  end
end
# rubocop:enable Style/Documentation, Style/RaiseArgs, Metrics/LineLength
# rubocop:enable Style/CaseEquality

# load models and stuff
require_relative 'app/models/group'
require_relative 'app/models/user'
require_relative 'app/models/package'
require_relative 'app/models/apikey'
require_relative 'app/models/domain'
require_relative 'app/models/dkim'
require_relative 'app/models/dkimsigning'
require_relative 'app/models/mailforwarding'
require_relative 'app/models/mailaccount'
require_relative 'app/models/mailsource'
require_relative 'app/models/mailalias'
require_relative 'app/models/ipv4address'
require_relative 'app/models/ipv6address'
require_relative 'app/models/phpruntime'
require_relative 'app/models/vhost'
require_relative 'app/models/shell'
require_relative 'app/models/sftpuser'
require_relative 'app/models/shelluser'
require_relative 'app/models/sshpubkey'
require_relative 'app/models/databaseuser'
require_relative 'app/models/database'
require_relative 'app/helpers/classes/authentication_error'
require_relative 'app/helpers/classes/apiresponse'
require_relative 'app/helpers/classes/apiresponse_error'
require_relative 'app/helpers/classes/apiresponse_success'

Dir.glob("#{lp}/app/policies/*.rb").each { |file| require file }
require "#{lp}/app/helpers/generic_helper.rb"

# finalize db layout when all models have been loaded
DataMapper.finalize

# create logdir
FileUtils.mkdir_p('log')
