# frozen_string_literal: true
require './vhost_api_app.rb'
Dir.glob('./app/controllers/*.rb').each { |f| require f }

# run VhostApi::App

map('/api/v2/example') { run VhostApi::Controllers::Example }
map('/api/v2.0/example') { run VhostApi::Controllers::Example }
map('/api/v2.0.0/example') { run VhostApi::Controllers::Example }
map('/') { run VhostApi::App }
