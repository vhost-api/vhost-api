# frozen_string_literal: true
require 'simplecov'
SimpleCov.profiles.define 'vhost-api' do
  add_filter 'vendor'

  add_group 'App', './(vhost_api_app.rb|init.rb)'
  add_group 'Controllers', 'controllers'
  add_group 'Models', 'models'
  add_group 'Helpers', 'helpers'
  add_group 'Policies', 'policies'
  add_group 'RSpec', 'spec'
end
SimpleCov.start 'vhost-api'

require 'rack/test'
require 'rspec'
require 'factory_girl'
require 'database_cleaner'
require File.expand_path '../support/pundit_matcher.rb', __FILE__

ENV['RACK_ENV'] = 'test'

require File.expand_path '../../vhost_api_app.rb', __FILE__

module RSpecMixin
  include Rack::Test::Methods
  def app
    Sinatra::Application
  end
end

RSpec.configure do |c|
  c.include RSpecMixin
  c.include FactoryGirl::Syntax::Methods

  c.before(:suite) do
    FactoryGirl.find_definitions
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  c.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
