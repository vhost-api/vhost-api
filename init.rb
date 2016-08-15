# frozen_string_literal: true

@environment = ENV['RACK_ENV'] || 'development'
@dbconfig = YAML.load(File.read('config/database.yml'))[@environment]

require 'bundler/setup'

require 'tempfile'
require 'data_mapper'
require 'dm-migrations'
require 'dm-constraints'
require 'dm-timestamps'
require 'dm-serializer'

case @dbconfig[:db_adapter].upcase
when 'POSTGRES'
  require 'dm-postgres-adapter'
when 'MYSQL'
  require 'dm-mysql-adapter'
end

require 'bcrypt'
require 'sshkey'

# load models and stuff
require_relative 'app/models/group'
require_relative 'app/models/package'
require_relative 'app/models/user'
require_relative 'app/models/apikey'
require_relative 'app/models/domain'
require_relative 'app/models/dkim'
require_relative 'app/models/dkimsigning'
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

Dir.glob('./app/policies/*.rb').each { |file| require file }
require './app/helpers/generic_helper.rb'

# finalize db layout when all models have been loaded
DataMapper.finalize
