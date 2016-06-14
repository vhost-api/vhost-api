# frozen_string_literal; false
require 'bundler/setup'

require 'data_mapper'
require 'dm-migrations'
require 'dm-constraints'
require 'dm-timestamps'
require 'dm-serializer'
require 'dm-mysql-adapter'
require 'dm-postgres-adapter'
require 'bcrypt'

# load models and stuff
require_relative 'models/group'
require_relative 'models/user'
require_relative 'models/apikey'
require_relative 'models/domain'
require_relative 'models/dkim'
require_relative 'models/dkimsigning'
require_relative 'models/mailaccount'
require_relative 'models/mailsource'
require_relative 'models/mailalias'
require_relative 'models/mailsourcepermission'
require_relative 'models/mailaliasdestination'
require_relative 'models/ipv4address'
require_relative 'models/ipv6address'
require_relative 'models/phpruntime'
require_relative 'models/aliasvhost'
require_relative 'models/vhost'
require_relative 'models/shell'
require_relative 'models/sftpuser'
require_relative 'models/shelluser'
require_relative 'models/sshpubkey'
require_relative 'models/databaseuser'
require_relative 'models/database'
require_relative 'models/env'
require_relative 'helpers/classes/apiresponse'
require_relative 'helpers/classes/apiresponse_error'
require_relative 'helpers/classes/apiresponse_success'

Dir.glob('./{helpers}/*.rb').each { |file| require file }

# finalize db layout when all models have been loaded
DataMapper.finalize
