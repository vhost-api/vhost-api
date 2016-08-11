# frozen_string_literal: true
# This class builds an api success response.
class ApiResponseSuccess < ApiResponse
  def initialize(status_code: 200, data: nil)
    super(status: 'success', status_code: status_code)
    @data = data
  end

  def to_json
    {
      status: @status,
      data: @data
    }.to_json
  end

  attr_reader :data
end
