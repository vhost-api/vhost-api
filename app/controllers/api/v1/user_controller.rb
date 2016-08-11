# frozen_string_literal: true
namespace '/api/v1/users' do
  get do
    @users = policy_scope(User)
    return_authorized_collection(object: @users, params: params)
  end

  post do
    @result = nil

    # check creation permissions. i.e. admin/quotacheck
    authorize(User, :create?)

    begin
      # get json data from request body and symbolize all keys
      request.body.rewind
      @_params = JSON.parse(request.body.read)
      @_params = symbolize_params_hash(@_params)

      # login must not be nil
      return_api_error(ApiErrors.[](:invalid_login)) if @_params[:login].nil?

      # check permissions for parameters
      raise Pundit::NotAuthorizedError unless policy(User).create_with?(
        @_params
      )

      @_user = User.new(@_params)
      if @_user.save
        @result = ApiResponseSuccess.new(status_code: 201,
                                         data: { object: @_user })
        loc = [request.base_url, 'api', 'v1', 'users', @_user.id].join('/')
        response.headers['Location'] = loc
      end
    rescue ArgumentError
      @result = api_error(ApiErrors.[](:invalid_request))
    rescue JSON::ParserError
      @result = api_error(ApiErrors.[](:malformed_request))
    rescue DataMapper::SaveFailureError
      @result = if User.first(login: @_params[:login]).nil?
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
    @_user = User.get(params[:id])
    return_api_error(ApiErrors.[](:not_found)) if @_user.nil?
  end

  namespace '/:id' do
    delete do
      @result = nil

      # check creation permissions. i.e. admin/quotacheck
      authorize(@_user, :destroy?)

      begin
        @result = if @_user.destroy
                    ApiResponseSuccess.new
                  else
                    api_error(ApiErrors.[](:failed_delete))
                  end
      end
      return_apiresponse @result
    end

    patch do
      @result = nil

      # check creation permissions. i.e. admin/quotacheck
      authorize(@_user, :update?)

      begin
        # get json data from request body and symbolize all keys
        request.body.rewind
        @_params = JSON.parse(request.body.read)
        @_params = symbolize_params_hash(@_params)

        # check permissions for parameters
        raise Pundit::NotAuthorizedError unless policy(@_user).update_with?(
          @_params
        )

        @result = if @_user.update(@_params)
                    ApiResponseSuccess.new(data: { object: @_user })
                  else
                    api_error(ApiErrors.[](:failed_update))
                  end
      rescue ArgumentError
        @result = api_error(ApiErrors.[](:invalid_request))
      rescue JSON::ParserError
        @result = api_error(ApiErrors.[](:malformed_request))
      rescue DataMapper::SaveFailureError
        @result = if User.first(login: @_params[:login]).nil?
                    api_error(ApiErrors.[](:failed_update))
                  else
                    api_error(ApiErrors.[](:resource_conflict))
                  end
      end
      return_apiresponse @result
    end

    get do
      return_authorized_resource(object: @_user) if authorize(@_user, :show?)
    end
  end
end
