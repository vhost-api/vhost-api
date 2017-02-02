# frozen_string_literal: true
require 'sinatra/base'
require 'api/controllers/application_controller'
require 'api/lib/example_module'

module VhostApi
  class Controllers
    # VhostApi Example controller
    class ExampleController < VhostApi::Controllers::Application
      include VhostApi::Modules::ExampleModule

      get '/' do
        index
      end

      get '/:id' do
        show(id: params[:id])
      end

      post '/' do
        create(params: params)
      end
    end
  end
end
