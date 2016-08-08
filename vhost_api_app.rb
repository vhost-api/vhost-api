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
Dir.glob('./controllers/*.rb').each { |file| require file }

# setup stuff
::Logger.class_eval { alias_method :write, :'<<' }
access_log = 'log/' + settings.environment.to_s + '_access.log'
access_logger = ::Logger.new(access_log)
error_log = 'log/' + settings.environment.to_s + '_error.log'
error_logger = ::File.new(error_log, 'a+')
error_logger.sync = true

configure do
  use ::Rack::CommonLogger, access_logger
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
  require './controllers/api/v1/' + f.to_s + '_controller.rb'
end

# optional modules
settings.api_modules.map(&:upcase).each do |apimod|
  optional_modules = []
  case apimod
  when 'EMAIL' then optional_modules.push(%w(
                                            domain
                                            dkim
                                            dkimsigning
                                            mailaccount
                                            mailalias
                                            mailsource
                                          ))
  # TODO: FIXME: no dns controllers exist yet
  when 'DNS' then optional_modules.push(%w(domain))
  when 'VHOST' then optional_modules.push(%w(
                                            domain
                                            ipv4address
                                            ipv6address
                                            phpruntime
                                            sftpuser
                                            shelluser
                                            vhost
                                          ))
  # TODO: FIXME: no database/databaseuser controllers exist yet
  when 'DATABASE' then nil
  end

  optional_modules.flatten.uniq.each do |f|
    require './controllers/api/v1/' + f.to_s + '_controller.rb'
  end
end

configure :development do
  require 'pry'
  require 'better_errors'
  require 'binding_of_caller'
  set :show_exceptions, :after_handler
  set :raise_errors, false
  use BetterErrors::Middleware
  BetterErrors.application_root = __dir__
  BetterErrors.use_pry!
end

configure :test do
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

# tell pundit how to find the user
current_user do
  authenticate!
end

# @return [Boolean]
def user?
  @user != nil
end

error AuthenticationError do
  headers['WWW-Authenticate'] = 'Basic realm="Vhost-API"'
  return_api_error(ApiErrors.[](:authentication_failed))
end

error Pundit::NotAuthorizedError do
  return_api_error(ApiErrors.[](:unauthorized))
end

before do
  authenticate! unless request.path_info.include?('/login')

  content_type :json, charset: 'utf-8'
  # last_modified settings.start_time
  # etag settings.start_time.to_s
  cache_control :public, :must_revalidate
end

get '/' do
  "Welcome #{@user.name} to VHost-API!"
end

get '/api_modules' do
  result = ''
  settings.api_modules.each do |apimod|
    result += 'Module: ' + apimod.to_s + "\n"
  end
  result
end

get '/env' do
  authenticate!
  return_json_pretty({ environment: settings.environment.to_s }.to_json)
end

not_found do
  return_api_error(ApiErrors.[](:not_found))
end
