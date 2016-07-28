# frozen_string_literal: true
require 'bundler/setup'

require 'sinatra'
require 'sinatra/contrib'
require 'sinatra/flash'
require 'sinatra/pundit'
require 'tilt/haml'
require 'json'
require 'active_support/inflector'
require 'securerandom'
require 'digest/sha1'
require 'logger'
require 'filesize'
require 'tilt/sass'
require 'sass'
require 'English'
require 'better_errors'
require 'binding_of_caller'

# load models and stuff
require_relative './init'
Dir.glob('./controllers/*.rb').each { |file| require file }
Dir.glob('./controllers/api/v1/*.rb').each { |file| require file }

# setup database connection
# DataMapper::Logger.new($stdout, :debug)
DataMapper::Logger.new($stdout, :info)
DataMapper::Property::String.length(255)
DataMapper::Model.raise_on_save_failure = true
DataMapper.setup(:default,
                 [@dbconfig[:db_adapter], '://',
                  @dbconfig[:db_user], ':', @dbconfig[:db_pass], '@',
                  @dbconfig[:db_host], '/', @dbconfig[:db_name]].join)

::Logger.class_eval { alias_method :write, :'<<' }
access_log = 'log/' + settings.environment.to_s + '_access.log'
access_logger = ::Logger.new(access_log)
error_log = 'log/' + settings.environment.to_s + '_error.log'
error_logger = ::File.new(error_log, 'a+')
error_logger.sync = true

configure do
  use ::Rack::CommonLogger, access_logger
  set :root, File.expand_path('../', __FILE__)
  set :views, File.expand_path('../views', __FILE__)
  set :jsdir, 'js'
  set :cssdir, 'css'
  enable :coffeescript
  set :cssengine, 'scss'
  set :start_time, Time.now
  @appconfig = YAML.load(
    File.read('config/appconfig.yml')
  )[settings.environment.to_s]
  @appconfig.keys.each do |key|
    set key, @appconfig[key]
  end
end

configure :development do
  require 'pry'
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

use Rack::Session::Cookie, secret: File.read('config/session.secret'),
                           key: settings.session[:key].to_s,
                           domain: settings.session[:domain].to_s,
                           expire_after: settings.session[:timeout],
                           path: settings.session[:path].to_s

before { env['rack.errors'] = error_logger }

# tell pundit how to find the user
current_user do
  User.get(session[:user_id])
end

# @return [Boolean]
def user?
  @user != nil
end

def unauthorized_msg
  'insufficient permissions or quota exhausted'
end

error Pundit::NotAuthorizedError do
  flash[:alert] = 'not authorized'
  return_apiresponse(
    ApiResponseError.new(status_code: 403,
                         error_id: 'unauthorized',
                         message: unauthorized_msg)
  )
end

before do
  authenticate! unless request.path_info.include?('/login')

  set_title
  set_sidebar_title
  # last_modified settings.start_time
  # etag settings.start_time.to_s
  # cache_control :public, :must_revalidate
end

# check if request wants json
before %r{/.*/} do
  if %r{.json$} =~ request.path_info
    content_type :json, charset: 'utf-8'
    request.accept.unshift('application/json')
    request.path_info = request.path_info.gsub(%r{.json$}, '')
  else
    content_type :html, 'charset' => 'utf-8'
  end
end

get '/js/*.js' do
  pass unless settings.coffeescript?
  last_modified File.mtime(settings.root + '/views/' + settings.jsdir)
  content_type :js
  cache_control :public, :must_revalidate
  coffee [settings.jsdir, params[:splat].first].join('/').to_sym
end

get '/css/*.css' do
  last_modified File.mtime(settings.root + '/views/' + settings.cssdir)
  content_type :css
  cache_control :public, :must_revalidate
  send(settings.cssengine,
       [settings.cssdir, params[:splat].first].join('/').to_sym)
end

get '/' do
  authenticate!
  haml :home, layout: :layout
end

get '/env' do
  authenticate!
  respond_to do |type|
    type.html do
      haml :envs, layout: false
    end

    type.json do
      return_json_pretty({ environment: settings.environment.to_s }.to_json)
    end
  end
end

get '/about' do
  authenticate!
  haml :about, layout: false
end

get '/contact' do
  authenticate!
  haml :contact, layout: false
end

not_found do
  return_apiresponse(
    ApiResponseError.new(status_code: 404,
                         error_id: 'not found',
                         message: 'requested resource does not exist')
  )
end
