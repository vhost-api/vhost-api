# frozen_string_literal: true
require 'bundler/setup'
require 'sinatra/base'
require 'sequel'
require 'yaml'
require 'safe_yaml'
require 'logger'
require_relative './app/helpers/format_helper'

# VhostApi base class
class VhostApi
  # VhostApi application class
  class App < Sinatra::Base
    helpers Sinatra::Format

    configure do
      set :app_version, '0.2.0-alpha'
      set :api_version, 'v2'
      use Rack::TempfileReaper
      use Rack::Deflater
      set :root, File.expand_path('../', __FILE__)
      set :start_time, Time.now
      set :logging, false
      @appconfig = YAML.safe_load(
        File.read("#{settings.root}/config/appconfig.yml")
      )[settings.environment.to_s]
      @appconfig.keys.each do |key|
        set key.to_sym, @appconfig[key]
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

    # setup access logging for dev/test purporses
    access_log = "#{settings.root}/log/#{settings.environment}_access.log"
    access_logger = ::Logger.new(access_log)
    err_log = "#{settings.root}/log/#{settings.environment}_error.log"
    err_logger = ::File.new(err_log, 'a+')
    err_logger.sync = true

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
    @dbconfig = YAML.safe_load(
      File.read("#{settings.root}/config/database.yml")
    )[settings.environment.to_s]

    case @dbconfig['db_adapter'].upcase
    when 'POSTGRES'
      require 'postgresql'
    when 'MYSQL'
      require 'mysql2'
      @dbconfig['db_adapter'] = 'mysql2'
    end

    DB = Sequel.connect(
      adapter:  @dbconfig['db_adapter'],
      host:     @dbconfig['db_host'],
      database: @dbconfig['db_name'],
      user:     @dbconfig['db_user'],
      password: @dbconfig['db_pass']
    )

    before do
      # enforce authentication everywhere except for login endpoint and home
      authenticate! unless %w(/api/v1/auth/login /).include?(request.path_info)

      content_type :json, charset: 'utf-8'
      cache_control :public, :must_revalidate

      env['rack.errors'] = err_logger unless settings.environment == :production
    end

    get '/' do
      return_json_pretty(
        { app_version: settings.app_version,
          api_version: settings.api_version }.to_json
      )
    end
  end
end
