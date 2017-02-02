# frozen_string_literal: true
require 'active_support/core_ext/hash'
require 'lib/error'

module VhostApi
  class Middleware
    # This class parses and merges json request bodies into to sinatra
    # params variable, when the content_type is :json.
    class JsonParams
      def initialize(app)
        @app = app
      end

      # Merges JSON body data into the Rack params.
      # Aborts unless the HTTP Accept Header is set to 'application/json'.
      #
      # @param env [Hash] the request environment
      # @return nil
      def call(env)
        accept = env['HTTP_ACCEPT']
        Rack::Response.new([], 406).finish unless accept == 'application/json'
        begin
          request = Rack::Request.new(env)
          JSON.parse(request.body.read).deep_symbolize_keys.each do |k, v|
            request.update_param(k, v)
          end
          @app.call(env)
        rescue
          raise Errors::SerializableError
        end
      end
    end
  end
end
