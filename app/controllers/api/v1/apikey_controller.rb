# frozen_string_literal: true
namespace '/api/v1/apikeys' do
  get do
    @apikeys = policy_scope(Apikey)
    return_authorized_collection(object: @apikeys, params: params)
  end

  post do
    @result = nil

    # check creation permissions. i.e. admin/quotacheck
    authorize(Apikey, :create?)

    begin
      # get json data from request body and symbolize all keys
      request.body.rewind
      @_params = JSON.parse(request.body.read)
      @_params = symbolize_params_hash(@_params)

      # generate fresh apikey if nil
      @_params[:apikey] = SecureRandom.hex(32) if @_params[:apikey].nil?

      # if apikey was provided it has to be 64 characters long
      return_api_error(
        ApiErrors.[](:apikey_too_short)
      ) if @_params[:apikey].length < 64

      # check permissions for parameters
      raise Pundit::NotAuthorizedError unless policy(Apikey).create_with?(
        @_params
      )

      @apikey = Apikey.new(@_params)
      if @apikey.save
        @result = ApiResponseSuccess.new(status_code: 201,
                                         data: { object: @apikey })
        loc = [request.base_url, 'api', 'v1', 'apikeys', @apikey.id].join('/')
        response.headers['Location'] = loc
      end
    rescue ArgumentError
      @result = api_error(ApiErrors.[](:invalid_request))
    rescue JSON::ParserError
      @result = api_error(ApiErrors.[](:malformed_request))
    rescue DataMapper::SaveFailureError
      @result = if Apikey.first(apikey: @_params[:apikey]).nil?
                  api_error(ApiErrors.[](:failed_create))
                else
                  api_error(ApiErrors.[](:resource_conflict))
                end
    end
    return_apiresponse @result
  end

  before %r{\A/(?<id>\d+)/?.*} do
    # namespace local before blocks are evaluate before global before blocks
    # thus we need to enforce authentication here
    authenticate! if @user.nil?
    @apikey = Apikey.get(params[:id])
    return_api_error(ApiErrors.[](:not_found)) if @apikey.nil?
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
                    api_error(ApiErrors.[](:failed_delete))
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
        @_params = symbolize_params_hash(@_params)

        # if apikey was provided it has to be 64 characters long
        if @_params.key?(:apikey)
          return_api_error(
            ApiErrors.[](:invalid_apikey)
          ) if @_params[:apikey].nil?

          return_api_error(
            ApiErrors.[](:apikey_too_short)
          ) if @_params[:apikey].length < 64
        end

        # prevent any action being performed on a detroyed resource
        return_api_error(ApiErrors.[](:failed_update)) if @apikey.destroyed?

        # check permissions for parameters
        raise Pundit::NotAuthorizedError unless policy(@apikey).update_with?(
          @_params
        )

        @result = if @apikey.update(@_params)
                    ApiResponseSuccess.new(data: { object: @apikey })
                  else
                    api_error(ApiErrors.[](:failed_update))
                  end
      rescue ArgumentError
        @result = api_error(ApiErrors.[](:invalid_request))
      rescue JSON::ParserError
        @result = api_error(ApiErrors.[](:malformed_request))
      rescue DataMapper::SaveFailureError
        @result = if Apikey.first(apikey: @_params[:apikey]).nil?
                    api_error(ApiErrors.[](:failed_update))
                  else
                    api_error(ApiErrors.[](:resource_conflict))
                  end
      end
      return_apiresponse @result
    end

    get do
      return_authorized_resource(object: @apikey) if authorize(@apikey, :show?)
    end
  end
end
