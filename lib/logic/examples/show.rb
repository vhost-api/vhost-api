# frozen_string_literal: true
require 'lib/repositories/example'
require 'lib/models/example'

module VhostApi
  module Logic
    module Example
      # This class handles showing one Example from controllers.
      class Show
        def initialize(id = 0)
          @repository = VhostApi::Repositories::Example.new
          @id = id
        end

        def call
          @repository.find(@id)
        end
      end
    end
  end
end
