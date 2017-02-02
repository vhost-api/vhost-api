# frozen_string_literal: true
require 'lib/repositories/example'
require 'lib/models/example'

module VhostApi
  module Logic
    module Example
      # This class handles showing all Examples from controllers.
      class Index
        def initialize
          @repository = VhostApi::Repositories::Example.new
        end

        def call
          @repository.all
        end
      end
    end
  end
end
