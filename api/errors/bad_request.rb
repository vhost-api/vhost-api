# frozen_string_literal: true
require 'lib/serializable_error'

module VhostApi
  module Errors
    # BadRequest Error
    class BadRequest < ::Errors::SerializableError
      def initialize(detail: 'bad request')
        @detail = detail
        super(status: 400, msg: @detail)
      end
    end
  end
end
