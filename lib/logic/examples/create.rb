# frozen_string_literal: true
require 'lib/repositories/example'
require 'lib/models/example'

module VhostApi
  module Logic
    module Example
      # This class handles creation of Examples from controllers.
      class Create
        def initialize(data = nil)
          @repository = VhostApi::Repositories::Example.new
          @data = data
        end

        def call
          @repository.create(@data)
        end
      end
    end
  end
end
