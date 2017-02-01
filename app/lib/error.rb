# frozen_string_literal: true
class Errors
  # Base class for our errors that custom errors will inherit from.
  class SerializableError < StandardError
    attr_reader :status, :msg, :headers
    def initialize(status: 500, msg: 'internal server error', headers: {})
      @status = status
      @msg = msg
      @headers = headers
    end

    def to_json
      {
        status: 'error',
        message: @msg
      }.to_json
    end
  end
end
