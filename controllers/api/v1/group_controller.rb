# frozen_string_literal: true
namespace '/api/v1/groups' do
  helpers do
    def fetch_scoped_groups
      @groups = policy_scope(Group)
    end
  end

  get do
    # authenticate!
    fetch_scoped_groups
    return_authorized_collection(object: @groups)
  end

  post do
    # authenticate!

    @result = nil

    # check creation permissions. i.e. admin/quotacheck
    unless authorize(Group, :create?)
      error_msg = 'insufficient permissions or quota exhausted'
      @result = ApiResponseError.new(status_code: 403,
                                     error_id: 'unauthorized',
                                     message: error_msg)
      return_apiresponse @result
    end

    begin
      # get json data from request body
      request.body.rewind
      @params = JSON.parse(request.body.read)

      @group = Group.new(params)
      if @group.save
        @result = ApiResponseSuccess.new(status_code: 201,
                                         data: { object: @group })
        response.headers['Location'] = [request.base_url,
                                        'api',
                                        'v1',
                                        'groups',
                                        @group.id].join('/')
      else
        # 500 = Internal Server Error
        @result = ApiResponseError.new(status_code: 500,
                                       error_id: 'could not create',
                                       message: $ERROR_INFO.to_s)
      end
    rescue ArgumentError
      # 422 = Unprocessable Entity
      @result = ApiResponseError.new(status_code: 422,
                                     error_id: 'invalid request data',
                                     message: $ERROR_INFO.to_s)
    rescue JSON::ParserError
      # 400 = Bad Request
      @result = ApiResponseError.new(status_code: 400,
                                     error_id: 'malformed request data',
                                     message: $ERROR_INFO.to_s)
    rescue DataObjects::IntegrityError
      # 409 = Conflict
      @result = ApiResponseError.new(status_code: 409,
                                     error_id: 'resource conflict',
                                     message: $ERROR_INFO.to_s)
    rescue DataMapper::SaveFailureError
      if Group.first(params).nil?
        # 500 = Internal Server Error
        @result = ApiResponseError.new(status_code: 500,
                                       error_id: 'could not create',
                                       message: $ERROR_INFO.to_s)
      else
        # 409 = Conflict
        @result = ApiResponseError.new(status_code: 409,
                                       error_id: 'resource conflict',
                                       message: $ERROR_INFO.to_s)
      end
    rescue
      p $ERROR_INFO
    end
    return_apiresponse @result
  end

  before %r{\A/(?<id>\d+)/?.*} do
    authenticate! if @user.nil?
    @group = Group.get(params[:id])
    return_apiresponse(
      ApiResponseError.new(status_code: 404,
                           error_id: 'not found',
                           message: 'requested resource does not exist')
    ) if @group.nil?
  end

  namespace '/:id' do
    delete do
      # authenticate!

      @result = nil

      # check creation permissions. i.e. admin/quotacheck
      unless authorize(@group, :destroy?)
        error_msg = 'insufficient permissions'
        @result = ApiResponseError.new(status_code: 403,
                                       error_id: 'unauthorized',
                                       message: error_msg)
        return_apiresponse @result
      end

      begin
        @result = if @group.destroy
                    ApiResponseSuccess.new
                  else
                    # 500 = Internal Server Error
                    ApiResponseError.new(status_code: 500,
                                         error_id: 'could not delete',
                                         message: $ERROR_INFO.to_s)
                  end
      end
      return_apiresponse @result
    end

    patch do
      # authenticate!

      @result = nil

      # check creation permissions. i.e. admin/quotacheck
      unless authorize(@group, :update?)
        error_msg = 'insufficient permissions'
        @result = ApiResponseError.new(status_code: 403,
                                       error_id: 'unauthorized',
                                       message: error_msg)
        return_apiresponse @result
      end

      begin
        # get json data from request body
        request.body.rewind
        @params = JSON.parse(request.body.read)

        @result = if @group.update(params)
                    ApiResponseSuccess.new(data: { object: @group })
                  else
                    # 500 = Internal Server Error
                    ApiResponseError.new(status_code: 500,
                                         error_id: 'could not update',
                                         message: $ERROR_INFO.to_s)
                  end
      rescue ArgumentError
        # 422 = Unprocessable Entity
        @result = ApiResponseError.new(status_code: 422,
                                       error_id: 'invalid request data',
                                       message: $ERROR_INFO.to_s)
      rescue JSON::ParserError
        # 400 = Bad Request
        @result = ApiResponseError.new(status_code: 400,
                                       error_id: 'malformed request data',
                                       message: $ERROR_INFO.to_s)
      rescue DataMapper::SaveFailureError
        if Group.first(params).nil?
          # 500 = Internal Server Error
          @result = ApiResponseError.new(status_code: 500,
                                         error_id: 'could not create',
                                         message: $ERROR_INFO.to_s)
        else
          # 409 = Conflict
          @result = ApiResponseError.new(status_code: 409,
                                         error_id: 'resource conflict',
                                         message: $ERROR_INFO.to_s)
        end
      end
      return_apiresponse @result
    end

    get do
      # authenticate!
      return_authorized_resource(object: @group) if authorize @group, :show?
    end
  end
end
