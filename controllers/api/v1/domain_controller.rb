# frozen_string_literal: true
namespace '/api/v1/domains' do
  get do
    @domains = policy_scope(Domain)
    return_authorized_collection(object: @domains, params: params)
  end

  post do
    @result = nil

    # check creation permissions. i.e. admin/quotacheck
    authorize(Domain, :create?)

    begin
      # get json data from request body and symbolize all keys
      request.body.rewind
      @_params = JSON.parse(request.body.read)
      @_params = symbolize_params_hash(@_params)

      # domain name must not be nil
      return_api_error(ApiErrors.[](:invalid_domain)) if @_params[:name].nil?

      # force lowercase on domain name
      @_params[:name].downcase!

      # check permissions for parameters
      raise Pundit::NotAuthorizedError unless policy(Domain).create_with?(
        @_params
      )

      @domain = Domain.new(@_params)
      if @domain.save
        @result = ApiResponseSuccess.new(status_code: 201,
                                         data: { object: @domain })
        response.headers['Location'] = [request.base_url,
                                        'api',
                                        'v1',
                                        'domains',
                                        @domain.id].join('/')
      end
    rescue ArgumentError
      @result = api_error(ApiErrors.[](:invalid_request))
    rescue JSON::ParserError
      @result = api_error(ApiErrors.[](:malformed_request))
    rescue DataMapper::SaveFailureError
      @result = if Domain.first(name: @_params[:name]).nil?
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
    @domain = Domain.get(params[:id])
    return_api_error(ApiErrors.[](:not_found)) if @domain.nil?
  end

  namespace '/:id' do
    delete do
      @result = nil

      # check creation permissions. i.e. admin/quotacheck
      authorize(@domain, :destroy?)

      begin
        @result = if @domain.destroy
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
      authorize(@domain, :update?)

      begin
        # get json data from request body and symbolize all keys
        request.body.rewind
        @_params = JSON.parse(request.body.read)
        @_params = symbolize_params_hash(@_params)

        # domain name must not be nil if present
        if @_params.key?(:name)
          return_api_error(
            ApiErrors.[](:invalid_domain)
          ) if @_params[:name].nil?

          # force lowercase on domain name
          @_params[:name].downcase!
        end

        # prevent any action being performed on a detroyed resource
        return_api_error(ApiErrors.[](:failed_delete)) if @domain.destroyed?

        # check permissions for parameters
        raise Pundit::NotAuthorizedError unless policy(@domain).update_with?(
          @_params
        )

        @result = if @domain.update(@_params)
                    ApiResponseSuccess.new(data: { object: @domain })
                  else
                    api_error(ApiErrors.[](:failed_update))
                  end
      rescue ArgumentError
        @result = api_error(ApiErrors.[](:invalid_request))
      rescue JSON::ParserError
        @result = api_error(ApiErrors.[](:malformed_request))
      rescue DataMapper::SaveFailureError
        @result = if Domain.first(name: @_params[:name]).nil?
                    api_error(ApiErrors.[](:failed_update))
                  else
                    api_error(ApiErrors.[](:resource_conflict))
                  end
      end
      return_apiresponse @result
    end

    get do
      return_authorized_resource(object: @domain) if authorize(@domain, :show?)
    end
  end
end
