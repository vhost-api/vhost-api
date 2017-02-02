# frozen_string_literal: true
require 'lib/repositories/example'
require 'lib/models/example'

module VhostApi
  module Logic
    module Example
      # This class handles updating an Example from controllers.
      class Update
        def initialize(id = 0, data = nil)
          @repository = VhostApi::Repositories::Example.new
          @id = id
          @data = data
        end

        def call
          @repository.update(@id, @data)
        end
      end
    end
  end
end
