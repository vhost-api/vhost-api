# frozen_string_literal: true
namespace '/api/v1/apikeys' do
  helpers do
    def fetch_scoped_apikeys
      @apikeys = policy_scope(Apikey)
    end
  end

  get do
    fetch_scoped_apikeys
    return_authorized_collection(object: @apikeys)
  end

  post do
    @result = nil

    # check creation permissions. i.e. admin/quotacheck
    authorize(Apikey, :create?)

    begin
      # get json data from request body and symbolize all keys
      request.body.rewind
      @_params = JSON.parse(request.body.read)
      @_params = @_params.reduce({}) do |memo, (k, v)|
        memo.tap { |m| m[k.to_sym] = v }
      end

      # generate fresh apikey if nil
      @_params[:apikey] = SecureRandom.hex(32) if @_params[:apikey].nil?

      # if apikey was provided it has to be 64 characters long
      msg_too_short = 'invalid apikey, has to be 64 characters'
      raise(ArgumentError, msg_too_short) if @_params[:apikey].length < 64

      # check permissions for parameters
      raise Pundit::NotAuthorizedError unless policy(Apikey).create_with?(
        @_params
      )

      @apikey = Apikey.new(@_params)
      if @apikey.save
        @result = ApiResponseSuccess.new(status_code: 201,
                                         data: { object: @apikey })
        response.headers['Location'] = [request.base_url,
                                        'api',
                                        'v1',
                                        'apikeys',
                                        @apikey.id].join('/')
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
      if Apikey.first(apikey: @_params[:apikey]).nil?
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

  before %r{\A/(?<id>\d+)/?.*} do
    # namespace local before blocks are evaluate before global before blocks
    # thus we need to enforce authentication here
    authenticate! if @user.nil?
    @apikey = Apikey.get(params[:id])
    return_apiresponse(
      ApiResponseError.new(status_code: 404,
                           error_id: 'not found',
                           message: 'requested resource does not exist')
    ) if @apikey.nil?
  end

  namespace '/:id' do
    delete do
      @result = nil

      # check creation permissions. i.e. admin/quotacheck
      authorize(@apikey, :destroy?)

      begin
        @result = if @apikey.destroy
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
      @result = nil

      # check update permissions. i.e. admin/owner/quotacheck
      authorize(@apikey, :update?)

      begin
        # get json data from request body and symbolize all keys
        request.body.rewind
        @_params = JSON.parse(request.body.read)
        @_params = @_params.reduce({}) do |memo, (k, v)|
          memo.tap { |m| m[k.to_sym] = v }
        end

        # apikey name must not be nil if present
        if @_params.key?(:apikey)
          raise(ArgumentError, 'invalid apikey') if @_params[:apikey].nil?
          msg_too_short = 'invalid apikey, has to be 64 characters'
          raise(ArgumentError, msg_too_short) if @_params[:apikey].length < 64
        end

        # prevent any action being performed on a detroyed resource
        return_apiresponse(
          ApiResponseError.new(status_code: 500,
                               error_id: 'could not delete',
                               message: $ERROR_INFO.to_s)
        ) if @apikey.destroyed?

        # check permissions for parameters
        raise Pundit::NotAuthorizedError unless policy(@apikey).update_with?(
          @_params
        )

        @result = if @apikey.update(@_params)
                    ApiResponseSuccess.new(data: { object: @apikey })
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
        if Apikey.first(apikey: @_params[:apikey]).nil?
          # 500 = Internal Server Error
          @result = ApiResponseError.new(status_code: 500,
                                         error_id: 'could not update',
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
      return_authorized_resource(object: @apikey) if authorize(@apikey, :show?)
    end
  end
end
