# frozen_string_literal: true
require './vhost_api_app.rb'
Dir.glob('./app/controllers/*.rb').each { |f| require f }

# run VhostApi::App

map('/api/v2/examples') { run VhostApi::Controllers::ExampleController }
map('/api/v2.0/examples') { run VhostApi::Controllers::ExampleController }
map('/api/v2.0.0/examples') { run VhostApi::Controllers::ExampleController }
map('/') { run VhostApi::App }
