# frozen_string_literal: true
module VhostApi
  # This is the parent class for all VhostApi responses.
  class Response
    def initialize(status_code: 500, error_id: nil, message: nil, data: {})
      status = case status_code
               when 200..399 then 'success'
               when 500..599 then 'fail'
               when 400..499 then 'error'
               else 'unknown'
               end
      @status = status
      @status_code = status_code
      @error_id = error_id
      @message = message
      @data = data
    end

    def to_json
      response = { status: @status }
      response[:error_id] = @error_id if @error_id
      response[:message] = @message if @message
      response[:data] = @data
      response.to_json
    end

    attr_reader :status, :status_code, :error_id, :message, :data
  end
end
