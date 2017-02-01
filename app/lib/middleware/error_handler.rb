# frozen_string_literal: true
require_relative '../error'

class VhostApi
  class Middleware
    # This class handles our errors.
    class ErrorHandler
      def initialize(app)
        @app = app
      end

      # Catches all errors that have been unhandled thus far.
      #
      # @param env [Hash] the request environment
      # @return nil
      def call(env)
        @app.call(env)
      rescue Errors::SerializableError => error
        Rack::Response.new(error.to_json, error.status, error.headers).finish
      rescue
        body = Error::SerializableError.new.to_json
        Rack::Response.new(body, 500).finish
      end
    end
  end
end
