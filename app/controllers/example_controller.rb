# frozen_string_literal: true
require 'sinatra/base'
require_relative './application_controller'

class VhostApi
  class Controllers
    # VhostApi Example controller
    class Example < VhostApi::Controllers::Application
      get '/' do
        "This is #{self}"
      end
    end
  end
end
