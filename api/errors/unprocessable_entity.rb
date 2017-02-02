# frozen_string_literal: true
require 'lib/serializable_error'

module VhostApi
  module Errors
    # UnprocessableEntity Error
    class UnprocessableEntity < ::Errors::SerializableError
      def initialize(detail: 'unprocessable entity')
        @detail = detail
        super(status: 422, msg: @detail)
      end
    end
  end
end
