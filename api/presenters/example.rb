# frozen_string_literal: true
require 'api/response'

module VhostApi
  # Presentation module
  module Presenters
    # Example model
    class Example < VhostApi::Response
      # Example collection
      class Collection < VhostApi::Response
        def initialize(status_code = 200, collection = {})
          super(status_code: status_code, data: { object: collection })
          @collection = collection
        end
      end

      def initialize(status_code = 200, element = {})
        super(status_code: status_code, data: { object: element })
        @element = element
      end
    end
  end
end
