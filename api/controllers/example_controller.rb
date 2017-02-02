# frozen_string_literal: true
require 'sinatra/base'
require 'api/controllers/application_controller'
require 'lib/logic/example'
require 'api/presenters/example'

module VhostApi
  class Controllers
    # VhostApi Example controller
    class ExampleController < VhostApi::Controllers::Application
      get '/' do
        logic = VhostApi::Logic::Example::Index.new
        presenter = VhostApi::Presenters::Example::Collection.new(200,
                                                                  logic.call)
        halt presenter.status_code, presenter.to_json
      end

      post '/' do
        logic = VhostApi::Logic::Example::Create.new(params)
        presenter = VhostApi::Presenters::Example.new(201, logic.call)
        halt presenter.status_code, presenter.to_json
      end

      get '/:id' do
        logic = VhostApi::Logic::Example::Show.new(params[:id])
        presenter = VhostApi::Presenters::Example.new(200, logic.call)
        halt presenter.status_code, presenter.to_json
      end

      delete '/:id' do
        logic = VhostApi::Logic::Example::Delete.new(params)
        presenter = VhostApi::Presenters::Example.new(204, logic.call)
        halt presenter.status_code, presenter.to_json
      end
    end
  end
end
