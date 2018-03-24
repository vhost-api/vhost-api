# frozen_string_literal: true

source 'https://rubygems.org'

# core
gem 'bcrypt', '~> 3.1'
gem 'sinatra', '~> 2.0.1'
gem 'sinatra-contrib', '~> 2.0.1'
gem 'sshkey', '~> 1.9.0'

# tools
gem 'rake', '~> 12.0', require: false

# authorization
# gem 'sinatra-pundit', '~> 0.1.0'
gem 'sinatra-pundit', git: 'https://github.com/vhost-api/sinatra-pundit.git'

# database
gem 'data_mapper', '~> 1.2.0'
gem 'data_objects', git: 'https://github.com/vhost-api/do.git', submodules: true
gem 'dm-constraints', '~> 1.2.0'

group :mysql do
  gem 'dm-mysql-adapter', '~> 1.2.0'
  gem 'do_mysql', '~> 0.10.17'
end

group :postgres do
  gem 'dm-postgres-adapter', '~> 1.2.0'
  gem 'do_postgres', '~> 0.10.17'
end

# engine
gem 'puma', '~> 3.11'

# style
gem 'activesupport', '~> 5.1.5'
gem 'filesize', '~> 0.1.1'

group :development do
  gem 'better_errors', '~> 2.4.0'
  gem 'binding_of_caller', '~> 0.8.0'
  gem 'guard', '~> 2.14.2', require: false
  gem 'guard-rspec', '~> 4.7.3', require: false
  gem 'pry', '~> 0.11.3'
  gem 'shotgun', '~> 0.9.2', require: false
end

group :test, :development do
  gem 'astrolabe', '~> 1.3.1', require: false
  gem 'faker', '~> 1.8.7', require: false
  gem 'rack-test', '~> 0.8.3', require: false
  gem 'rspec', '~> 3.7.0', require: false
  gem 'rubocop', '~> 0.54.0', require: false
  gem 'rubocop-rspec', '~> 1.24.0', require: false
  gem 'simplecov', '~> 0.16.1', require: false
  gem 'yard', '~> 0.9.12', require: false
end

group :test do
  gem 'database_cleaner', '~> 1.6.2'
  gem 'factory_girl', '~> 4.9.0'
end
