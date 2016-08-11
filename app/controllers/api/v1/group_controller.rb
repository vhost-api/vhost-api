# frozen_string_literal: true
namespace '/api/v1/groups' do
  get do
    @groups = policy_scope(Group)
    return_authorized_collection(object: @groups, params: params)
  end

  post do
    @result = nil

    # check creation permissions. i.e. admin/quotacheck
    authorize(Group, :create?)

    begin
      # get json data from request body and symbolize all keys
      request.body.rewind
      @_params = JSON.parse(request.body.read)
      @_params = symbolize_params_hash(@_params)

      # group name must not be nil
      return_api_error(ApiErrors.[](:invalid_group)) if @_params[:name].nil?

      @group = Group.new(@_params)
      if @group.save
        @result = ApiResponseSuccess.new(status_code: 201,
                                         data: { object: @group })
        loc = [request.base_url, 'api', 'v1', 'groups', @group.id].join('/')
        response.headers['Location'] = loc
      end
    rescue ArgumentError
      @result = api_error(ApiErrors.[](:invalid_request))
    rescue JSON::ParserError
      @result = api_error(ApiErrors.[](:malformed_request))
    rescue DataMapper::SaveFailureError
      @result = if Group.first(name: @_params[:name]).nil?
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
    @group = Group.get(params[:id])
    return_api_error(ApiErrors.[](:not_found)) if @group.nil?
  end

  namespace '/:id' do
    delete do
      @result = nil

      # check creation permissions. i.e. admin/quotacheck
      authorize(@group, :destroy?)

      begin
        @result = if @group.destroy
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
      authorize(@group, :update?)

      begin
        # get json data from request body and symbolize all keys
        request.body.rewind
        @_params = JSON.parse(request.body.read)
        @_params = symbolize_params_hash(@_params)

        # group name must not be nil if present
        if @_params.key?(:name)
          return_api_error(
            ApiErrors.[](:invalid_group)
          ) if @_params[:name].nil?
        end

        @result = if @group.update(@_params)
                    ApiResponseSuccess.new(data: { object: @group })
                  else
                    api_error(ApiErrors.[](:failed_update))
                  end
      rescue ArgumentError
        @result = api_error(ApiErrors.[](:invalid_request))
      rescue JSON::ParserError
        @result = api_error(ApiErrors.[](:malformed_request))
      rescue DataMapper::SaveFailureError
        @result = if Group.first(name: @_params[:name]).nil?
                    api_error(ApiErrors.[](:failed_update))
                  else
                    api_error(ApiErrors.[](:resource_conflict))
                  end
      end
      return_apiresponse @result
    end

    get do
      return_authorized_resource(object: @group) if authorize(@group, :show?)
    end
  end
end
