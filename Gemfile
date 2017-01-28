# frozen_string_literal: true
source 'https://rubygems.org'

# core
gem 'bcrypt'
gem 'sinatra'
gem 'sinatra-contrib'
gem 'sshkey'
# tools
gem 'rake', require: false
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
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'guard', require: false
  gem 'guard-rspec', require: false
  gem 'pry'
  gem 'shotgun', require: false
end

group :test, :development do
  gem 'astrolabe', require: false
  gem 'faker', require: false
  gem 'rspec', require: false
  gem 'rubocop', require: false
  gem 'rubocop-rspec', require: false
  gem 'simplecov', require: false
  gem 'yard', require: false
end

group :test do
  gem 'database_cleaner'
  gem 'factory_girl'
end
