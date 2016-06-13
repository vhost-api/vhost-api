# frozen_string_literal: true
# This abstract class is the base for each api response.
class ApiResponse
  def initialize(status: status_code)
    @status = status
    @status_code = status_code
  end

  attr_reader :status, :status_code
end
