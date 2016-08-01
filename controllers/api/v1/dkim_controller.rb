# frozen_string_literal: true
namespace '/api/v1/dkims' do
  helpers do
    def fetch_scoped_dkims
      @dkims = policy_scope(Dkim)
    end
  end

  get do
    fetch_scoped_dkims
    return_authorized_collection(object: @dkims)
  end

  post do
    @result = nil

    # check creation permissions. i.e. admin/quotacheck
    authorize(Dkim, :create?)

    begin
      # get json data from request body and symbolize all keys
      request.body.rewind
      @_params = JSON.parse(request.body.read)
      @_params = @_params.reduce({}) do |memo, (k, v)|
        memo.tap { |m| m[k.to_sym] = v }
      end

      # selector must not be nil
      raise(ArgumentError, 'invalid selector') if @_params[:selector].nil?

      # domain_id must not be nil
      raise(ArgumentError, 'invalid domain id') if @_params[:domain_id].nil?

      # force lowercase on selector
      @_params[:selector].downcase!

      # check permissions for parameters
      raise Pundit::NotAuthorizedError unless policy(Dkim).create_with?(
        @_params
      )

      @dkim = Dkim.new(@_params)
      if @dkim.save
        @result = ApiResponseSuccess.new(status_code: 201,
                                         data: { object: @dkim })
        response.headers['Location'] = [request.base_url,
                                        'api',
                                        'v1',
                                        'dkims',
                                        @dkim.id].join('/')
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
      # 500 = Internal Server Error
      @result = ApiResponseError.new(status_code: 500,
                                     error_id: 'could not create',
                                     message: $ERROR_INFO.to_s)
    end
    return_apiresponse @result
  end

  before %r{\A/(?<id>\d+)/?.*} do
    # namespace local before blocks are evaluate before global before blocks
    # thus we need to enforce authentication here
    authenticate! if @user.nil?
    @dkim = Dkim.get(params[:id])
    return_apiresponse(
      ApiResponseError.new(status_code: 404,
                           error_id: 'not found',
                           message: 'requested resource does not exist')
    ) if @dkim.nil?
  end

  namespace '/:id' do
    delete do
      @result = nil

      # prevent any action being performed on a detroyed resource
      return_apiresponse(
        ApiResponseError.new(status_code: 500,
                             error_id: 'could not delete',
                             message: $ERROR_INFO.to_s)
      ) if @dkim.destroyed?

      # check creation permissions. i.e. admin/quotacheck
      authorize(@dkim, :destroy?)

      begin
        @result = if @dkim.destroy
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
      authorize(@dkim, :update?)

      begin
        # get json data from request body and symbolize all keys
        request.body.rewind
        @_params = JSON.parse(request.body.read)
        @_params = @_params.reduce({}) do |memo, (k, v)|
          memo.tap { |m| m[k.to_sym] = v }
        end

        # prevent any action being performed on a detroyed resource
        return_apiresponse(
          ApiResponseError.new(status_code: 500,
                               error_id: 'could not delete',
                               message: $ERROR_INFO.to_s)
        ) if @dkim.destroyed?

        if @_params.key?(:selector)
          # selector must not be nil
          raise(ArgumentError, 'invalid selector') if @_params[:selector].nil?
        end

        if @_params.key?(:domain_id)
          # domain_id must not be nil
          raise(ArgumentError, 'invalid domain id') if @_params[:domain_id].nil?
        end

        # force lowercase on selector
        @_params[:selector].downcase! if @_params.key?(:selector)

        # check permissions for parameters
        raise Pundit::NotAuthorizedError unless policy(
          @dkim
        ).update_with?(
          @_params
        )

        @result = if @dkim.update(@_params)
                    ApiResponseSuccess.new(data: { object: @dkim })
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
        # 500 = Internal Server Error
        @result = ApiResponseError.new(status_code: 500,
                                       error_id: 'could not update',
                                       message: $ERROR_INFO.to_s)
      end
      return_apiresponse @result
    end

    get do
      return_authorized_resource(object: @dkim) if authorize(
        @dkim,
        :show?
      )
    end
  end
end
