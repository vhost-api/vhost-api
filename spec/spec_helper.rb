# frozen_string_literal: true

require 'simplecov'

# SimpleCov.profiles.define 'vhost-api' do
#   add_filter 'vendor'
#
#   add_group 'RSpec', './spec'
#   add_group 'App', './(vhost_api_app.rb|init.rb)'
#   add_group 'Controllers', './app/controllers/'
#   add_group 'Models', './app/models/'
#   add_group 'Helpers', './app/helpers/'
#   add_group 'Policies', './app/policies/'
# end
# SimpleCov.start 'vhost-api'

require File.expand_path '../../vhost_api_app.rb', __FILE__
require 'rspec'
require 'rack/test'
require 'factory_girl'
require 'database_cleaner'
require File.expand_path '../support/pundit_matcher.rb', __FILE__
require File.expand_path '../support/auth_helper.rb', __FILE__
require File.expand_path '../support/format_helper.rb', __FILE__

ENV['RACK_ENV'] = 'test'

module RSpecMixin
  include Rack::Test::Methods
  def app
    Sinatra::Application
  end
end

RSpec.configure do |c|
  c.include RSpecMixin
  c.include FactoryGirl::Syntax::Methods
  c.include AuthHelpers
  c.include FormatHelpers

  c.before(:suite) do
    FactoryGirl.find_definitions
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  c.around do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
