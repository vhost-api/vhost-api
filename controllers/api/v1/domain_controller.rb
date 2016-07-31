# frozen_string_literal: true
namespace '/api/v1/domains' do
  helpers do
    def fetch_scoped_domains
      @domains = policy_scope(Domain)
    end
  end

  get do
    fetch_scoped_domains
    return_authorized_collection(object: @domains)
  end

  post do
    @result = nil

    # check creation permissions. i.e. admin/quotacheck
    authorize(Domain, :create?)

    begin
      # get json data from request body and symbolize all keys
      request.body.rewind
      @_params = JSON.parse(request.body.read)
      @_params = @_params.reduce({}) do |memo, (k, v)|
        memo.tap { |m| m[k.to_sym] = v }
      end

      # domain name must not be nil
      raise(ArgumentError, 'invalid domain name') if @_params[:name].nil?

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
      if Domain.first(name: @_params[:name]).nil?
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
    @domain = Domain.get(params[:id])
    return_apiresponse(
      ApiResponseError.new(status_code: 404,
                           error_id: 'not found',
                           message: 'requested resource does not exist')
    ) if @domain.nil?
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
      authorize(@domain, :update?)

      begin
        # get json data from request body and symbolize all keys
        request.body.rewind
        @_params = JSON.parse(request.body.read)
        @_params = @_params.reduce({}) do |memo, (k, v)|
          memo.tap { |m| m[k.to_sym] = v }
        end

        # domain name must not be nil
        raise(ArgumentError, 'invalid domain name') if @_params[:name].nil?

        # force lowercase on domain name
        @_params[:name].downcase!

        # prevent any action being performed on a detroyed resource
        return_apiresponse(
          ApiResponseError.new(status_code: 500,
                               error_id: 'could not delete',
                               message: $ERROR_INFO.to_s)
        ) if @domain.destroyed?

        # check permissions for parameters
        raise Pundit::NotAuthorizedError unless policy(@domain).update_with?(
          @_params
        )

        @result = if @domain.update(@_params)
                    ApiResponseSuccess.new(data: { object: @domain })
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
        # my_logger.debug("UPDATE fail w/ SaveFailureError exception")
        if Domain.first(name: @_params[:name]).nil?
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
      return_authorized_resource(object: @domain) if authorize(@domain, :show?)
    end
  end
end
