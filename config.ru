# frozen_string_literal: true
$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))

require 'vhost_api_app'
Dir.glob('./api/controllers/*.rb').each { |f| require f }

# run VhostApi::App

map('/api/v2/examples') { run VhostApi::Controllers::ExampleController }
map('/api/v2.0/examples') { run VhostApi::Controllers::ExampleController }
map('/api/v2.0.0/examples') { run VhostApi::Controllers::ExampleController }
map('/') { run VhostApi::App }
