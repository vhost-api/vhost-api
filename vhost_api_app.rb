# frozen_string_literal: true
require 'bundler/setup'

require 'sinatra'
require 'sinatra/contrib'
require 'sinatra/pundit'
require 'json'
require 'active_support/inflector'
require 'securerandom'
require 'digest/sha1'
require 'logger'
require 'filesize'
require 'English'

# load models and stuff
require_relative './init'

# load additional helpers
Dir.glob('./app/helpers/*.rb').each { |file| require file }

configure do
  set :app_version, '0.1.2-alpha'
  set :api_version, 'v1'
  use Rack::TempfileReaper
  use Rack::Deflater
  set :root, File.expand_path('../', __FILE__)
  set :start_time, Time.now
  set :logging, false
  @appconfig = YAML.load(
    File.read("#{settings.root}/config/appconfig.yml")
  )[settings.environment.to_s]
  @appconfig.keys.each do |key|
    set key, @appconfig[key]
  end
end

# setup logging
case settings.log_method
when 'internal' then
  my_env = settings.environment
  vhost_api_logfile_name = "#{settings.root}/log/vhost-api_#{my_env}.log"
  vhost_api_logfile = ::File.new(vhost_api_logfile_name, 'a+')
  vhost_api_logfile.sync = true
  vhost_api_logger = Logger.new(vhost_api_logfile)
when 'syslog' then
  require 'syslog/logger'
  vhost_api_logger = Syslog::Logger.new("vhost-api_#{settings.environment}")
else
  abort('ERROR: error parsing appconfig.yml: invalid log_method')
end
vhost_api_logger.level = Logger.const_get(settings.log_level.upcase)

# -- load only activated modules/controllers --
# core modules
%w(group user package apikey auth).each do |f|
  require "#{settings.root}/app/controllers/api/v1/" + f.to_s + '_controller.rb'
end

# optional modules
settings.api_modules.map(&:upcase).each do |apimod|
  optional_modules = []
  case apimod
  when 'EMAIL' then optional_modules.push(
    %w(domain dkim dkimsigning mailaccount mailalias mailsource mailforwarding)
  )
  when 'VHOST' then optional_modules.push(
    %w(domain ipv4address ipv6address phpruntime sftpuser shelluser vhost)
  )
  # TODO: no dns controllers exist yet
  when 'DNS' then optional_modules.push(%w(domain))
  # TODO: no database/databaseuser controllers exist yet
  when 'DATABASE' then nil
  end

  optional_modules.flatten.uniq.each do |f|
    require "#{settings.root}/app/controllers/api/v1/#{f}_controller.rb"
  end
end

# setup access logging for dev/test purporses
access_log = settings.root + '/log/' + settings.environment.to_s + '_access.log'
access_logger = ::Logger.new(access_log)
error_log = settings.root + '/log/' + settings.environment.to_s + '_error.log'
error_logger = ::File.new(error_log, 'a+')
error_logger.sync = true

configure :development, :test do
  require 'pry'
  require 'better_errors'
  require 'binding_of_caller'
  set :show_exceptions, :after_handler
  set :raise_errors, false
  set :dump_errors, true
  use BetterErrors::Middleware
  BetterErrors.application_root = __dir__
  BetterErrors.use_pry!
  set :app_logger, vhost_api_logger
  use ::Rack::CommonLogger, access_logger
end

configure :production do
  set :show_exceptions, false
  set :raise_errors, false
  set :dump_errors, false
  set :app_logger, vhost_api_logger
end

# setup database connection
DataMapper::Logger.new(
  "#{settings.root}/log/datamapper_#{settings.environment}",
  :info
)
DataMapper::Property::String.length(255)
DataMapper::Model.raise_on_save_failure = true
DataMapper.setup(:default,
                 [
                   @dbconfig[:db_adapter],
                   '://',
                   @dbconfig[:db_user],
                   ':',
                   @dbconfig[:db_pass],
                   '@',
                   @dbconfig[:db_host],
                   ':',
                   @dbconfig[:db_port],
                   '/',
                   @dbconfig[:db_name]
                 ].join)

before do
  # enforce authentication everywhere except for login endpoint and home
  authenticate! unless %w(/api/v1/auth/login /).include?(request.path_info)

  content_type :json, charset: 'utf-8'
  cache_control :public, :must_revalidate

  env['rack.errors'] = error_logger unless settings.environment == :production
end

get '/' do
  return_json_pretty(
    { app_version: settings.app_version,
      api_version: settings.api_version }.to_json
  )
end
