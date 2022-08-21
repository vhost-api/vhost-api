# frozen_string_literal: true

source 'https://rubygems.org'

# core
gem 'bcrypt', '~> 3.1', '>= 3.1.18'
gem 'json', '~> 2.3', '>= 2.3.0'
gem 'json_pure', '~> 2.3', '>= 2.3.0'
gem 'sinatra', '~> 2.2', '>= 2.2.2'
gem 'sinatra-contrib', '~> 2.2', '>= 2.2.2'
gem 'sshkey', '~> 2.0'

# tools
gem 'rake', '~> 13.0', require: false

# authorization
gem 'sinatra-pundit', '~> 0.2'

# database
gem 'data_mapper', '~> 1.2'
gem 'dm-constraints', '~> 1.2'
gem 'dm-serializer', git: 'https://github.com/vhost-api/dm-serializer.git', branch: 'new_json'
gem 'dm-types', git: 'https://github.com/vhost-api/dm-types.git', branch: 'new_json'

group :mysql do
  gem 'dm-mysql-adapter', '~> 1.2'
end

group :postgres do
  gem 'dm-postgres-adapter', '~> 1.2'
end

# engine
gem 'puma', '~> 4.3', '>= 4.3.12'

# style
gem 'activesupport', '~> 7.0'
gem 'filesize', '~> 0.2'

group :development do
  gem 'better_errors', '~> 2.9', '>= 2.9.1'
  gem 'binding_of_caller', '~> 1.0'
  gem 'guard', '~> 2.18', require: false
  gem 'guard-rspec', '~> 4.7', '>= 4.7.3', require: false
  gem 'pry', '~> 0.14', '>= 0.14.1'
  gem 'shotgun', '~> 0.9', '>= 0.9.2', require: false
end

group :test, :development do
  gem 'astrolabe', '~> 1.3', '>= 1.3.1', require: false
  gem 'faker', '~> 1.8', '>= 1.8.7', require: false
  gem 'rack-test', '~> 0.8', '>= 0.8.3', require: false
  gem 'rspec', '~> 3.7', require: false
  gem 'rubocop', '~> 0.54', require: false
  gem 'rubocop-rspec', '~> 1.24', require: false
  gem 'simplecov', '~> 0.21', require: false
  gem 'yard', '~> 0.9', require: false
end

group :test do
  gem 'database_cleaner', '~> 1.6'
  gem 'factory_bot', '~> 4.8'
end
