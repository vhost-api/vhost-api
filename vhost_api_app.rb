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

# setup stuff
::Logger.class_eval { alias_method :write, :'<<' }
access_log = 'log/' + settings.environment.to_s + '_access.log'
access_logger = ::Logger.new(access_log)
error_log = 'log/' + settings.environment.to_s + '_error.log'
error_logger = ::File.new(error_log, 'a+')
error_logger.sync = true

configure do
  use ::Rack::CommonLogger, access_logger
  use Rack::TempfileReaper
  set :root, File.expand_path('../', __FILE__)
  set :start_time, Time.now
  @appconfig = YAML.load(
    File.read('config/appconfig.yml')
  )[settings.environment.to_s]
  @appconfig.keys.each do |key|
    set key, @appconfig[key]
  end
end

# -- load only activated modules/controllers --
# core modules
%w(group user apikey auth).each do |f|
  require './app/controllers/api/v1/' + f.to_s + '_controller.rb'
end

# optional modules
settings.api_modules.map(&:upcase).each do |apimod|
  optional_modules = []
  case apimod
  when 'EMAIL' then optional_modules.push(
    %w(domain dkim dkimsigning mailaccount mailalias mailsource)
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
    require './app/controllers/api/v1/' + f.to_s + '_controller.rb'
  end
end

configure :development, :test do
  require 'pry'
  require 'better_errors'
  require 'binding_of_caller'
  set :show_exceptions, :after_handler
  set :raise_errors, false
  use BetterErrors::Middleware
  BetterErrors.application_root = __dir__
  BetterErrors.use_pry!
end

configure :production do
  set :show_exceptions, false
  set :raise_errors, false
end

# setup database connection
# DataMapper::Logger.new($stdout, :debug)
DataMapper::Logger.new("log/datamapper_#{settings.environment}", :info)
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
                   '/',
                   @dbconfig[:db_name]
                 ].join)

before { env['rack.errors'] = error_logger }

before do
  # enforce authentication everywhere except for login endpoints
  authenticate! unless request.path_info.include?('/login')

  content_type :json, charset: 'utf-8'
  cache_control :public, :must_revalidate
end

get '/' do
  "Welcome #{@user.name} to VHost-API!"
end
