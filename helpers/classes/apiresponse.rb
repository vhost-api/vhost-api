# frozen_string_literal: true
# This abstract class is the base for each api response.
class ApiResponse
  def initialize(status: nil, status_code: nil)
    @status = status
    @status_code = status_code
  end

  attr_reader :status, :status_code
end
