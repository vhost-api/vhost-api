source 'https://rubygems.org'

# core
gem 'sinatra'
gem 'sinatra-contrib', require: false
gem 'sinatra-logger'
gem 'bcrypt'
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

group :sqlite do
  gem 'dm-sqlite-adapter'
end

group :postgres do
  gem 'dm-postgres-adapter'
end

gem 'dm-constraints'
# engine
gem 'puma'
# style
gem 'sinatra-flash'
gem 'activesupport'
gem 'haml'
gem 'filesize'
gem 'sass'


group :development do
  gem 'shotgun', require: false
end

group :test, :development do
  gem 'rubocop', require: false
  gem 'astrolabe', require: false
  gem 'haml-lint', require: false
end
