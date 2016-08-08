# frozen_string_literal: true
source 'https://rubygems.org'

# core
gem 'sinatra'
gem 'sinatra-contrib'
gem 'sinatra-logger'
gem 'bcrypt'
gem 'sshkey'
# tools
gem 'rake', require: false
gem 'logger'
# authorization
gem 'sinatra-pundit'
# database
gem 'data_mapper'

group :mysql do
  gem 'dm-mysql-adapter'
end

group :postgres do
  gem 'dm-postgres-adapter'
end

gem 'dm-constraints'
# engine
gem 'puma'
# style
gem 'activesupport'
gem 'filesize'

group :development do
  gem 'shotgun', require: false
  gem 'pry'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'guard', require: false
  gem 'guard-rspec', require: false
end

group :test, :development do
  gem 'yard', require: false
  gem 'simplecov', require: false
  gem 'rspec', require: false
  gem 'rubocop', require: false
  gem 'rubocop-rspec', require: false
  gem 'astrolabe', require: false
  gem 'haml-lint', require: false
  gem 'faker', require: false
end

group :test do
  gem 'database_cleaner'
  gem 'factory_girl'
end
