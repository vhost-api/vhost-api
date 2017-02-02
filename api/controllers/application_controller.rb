# frozen_string_literal: true
require 'sinatra/base'
require 'multi_json'
require 'vhost_api_app'

module VhostApi
  module Controllers
    # VhostApi Application controller
    class Application < VhostApi::App
      get '/' do
        "Hello from #{self}"
      end
    end
  end
end
