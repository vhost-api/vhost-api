# frozen_string_literal: true
require 'sinatra/base'
require 'multi_json'
require_relative '../../vhost_api_app'

class VhostApi
  class Controllers
    # VhostApi Application controller
    class Application < VhostApi::App
      get '/' do
        "Hello from #{self}"
      end
    end
  end
end
