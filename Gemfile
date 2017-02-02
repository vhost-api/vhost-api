# frozen_string_literal: true
source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# core
# gem 'activesupport', '~> 5.0.1'
gem 'bcrypt', '~> 3.1.11'
gem 'multi_json', '~> 1.12.1'
gem 'safe_yaml', '~> 1.0.4'
gem 'sinatra', github: 'sinatra/sinatra'

# tools
gem 'rake', '~> 12.0.0', require: false

# authorization
gem 'sinatra-pundit', github: 'vhost-api/sinatra-pundit'

# database
gem 'sequel', '~> 4.42.1'
group :mysql do
  gem 'mysql2', '~> 0.4.5'
end
group :postgres do
  gem 'postgresql', '~> 1.0.0'
end

# engine
gem 'puma', '~> 3.7.0'

# required for both testing and developing
group :test, :development do
  gem 'astrolabe', '~> 1.3.1', require: false
  gem 'faker', '~> 1.7.2', require: false
  gem 'rspec', '~> 3.5.0', require: false
  gem 'rubocop', '~> 0.47.1', require: false
  gem 'rubocop-rspec', '~> 1.10.0', require: false
  gem 'simplecov', '~> 0.13', require: false
  gem 'yard', '~> 0.9.8', require: false
end

# development gems
group :development do
  gem 'better_errors', '~> 2.1.1'
  gem 'binding_of_caller', '~> 0.7.2'
  gem 'guard', '~> 2.14.0', require: false
  gem 'guard-rspec', '~> 4.7.3', require: false
  gem 'pry', '~> 0.10.4'
  gem 'shotgun', '~> 0.9.2', require: false
end

# test gems
group :test do
  gem 'database_cleaner', '~> 1.5.3'
  gem 'factory_girl', '~> 4.8.0'
end
