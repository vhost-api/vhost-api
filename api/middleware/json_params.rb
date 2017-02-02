# frozen_string_literal: true
require 'api/errors/bad_request'
require 'api/errors/unprocessable_entity'

module VhostApi
  module Middleware
    # This class parses and merges json request bodies into to sinatra
    # params variable, when the content_type is :json.
    class JsonParams
      # An error indicatating that parsing the json body failed
      class ParseError < VhostApi::Errors::BadRequest
        def initialize(error)
          super(detail: "parsing json failed: #{error.message}")
        end
      end

      # An error raised if body is nil or empty
      class EmptyBodyError < VhostApi::Errors::BadRequest
        def initialize
          super(detail: 'cannot process empty body')
        end
      end

      # An error raised on invalid content types
      class InvalidContentTypeError < VhostApi::Errors::BadRequest
        def initialize(content_type)
          super(detail: "cannot process content type #{content_type}")
        end
      end

      # An error raised if the top level of the json document is not a hash
      class NotAnObjectError < VhostApi::Errors::UnprocessableEntity
        def initialize
          super(detail: "document's top level must be an object")
        end
      end

      def initialize(app)
        @app = app
      end

      # Merges JSON body data into the Rack params.
      # Aborts unless the HTTP Accept Header is set to 'application/json'.
      #
      # @param env [Hash] the request environment
      # @return nil
      def call(env)
        parse(env)
        @app.call(env)
      end

      private

      def should_have_body?(env)
        env.key?('CONTENT_LENGTH')
      end

      def parse(env)
        return unless should_have_body?(env)

        request = Rack::Request.new(env)
        body = request.body.read
        request.body.rewind
        validate_request!(request, body)

        parsed_body = JSON.parse(body)
        raise NotAnObjectError unless parsed_body.is_a?(Hash)

        env['rack.request.form_input'] = request.body
        env['rack.request.form_hash'] = parsed_body
      rescue JSON::ParserError => error
        raise ParseError, error
      end

      def validate_request!(request, body)
        raise EmptyBodyError if body.nil? || body.empty?
        c_type = request.content_type

        return if c_type.match?(%r{^application/(vnd\.vhost-api\+)?json($| )})
        raise InvalidContentTypeError, content_type
      end
    end
  end
end
