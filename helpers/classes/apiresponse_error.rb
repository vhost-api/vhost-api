class ApiResponseError < ApiResponse
  def initialize(status_code: 500, error_id:, message:, data: nil)
    status = ""
    case status_code
    when 500 .. 599
      status = "fail"
    when 400 .. 499
      status = "error"
    else
      status = "unknown"
    end
    super(status: status, status_code: status_code)
    @error_id = error_id
    @message = message
    @data = data
  end

  def to_json
    {status: @status, error_id: @error_id, message: @message, data: @data}.to_json
  end

  attr_reader :error_id, :message, :data
end
