# frozen_string_literal: true
namespace '/api/v1/mailsources' do
  helpers do
    def fetch_scoped_mailsources
      @mailsources = policy_scope(MailSource)
    end
  end

  get do
    fetch_scoped_mailsources
    return_authorized_collection(object: @mailsources)
  end

  post do
    @result = nil

    # check creation permissions. i.e. admin/quotacheck
    authorize(MailSource, :create?)

    begin
      # get json data from request body and symbolize all keys
      request.body.rewind
      @_params = JSON.parse(request.body.read)
      @_params = @_params.reduce({}) do |memo, (k, v)|
        memo.tap { |m| m[k.to_sym] = v }
      end

      # email addr must not be nil
      raise(ArgumentError, 'invalid email address') if @_params[:address].nil?

      # force lowercase on email addr
      @_params[:address].downcase!

      # check permissions for parameters
      raise Pundit::NotAuthorizedError unless policy(MailSource).create_with?(
        @_params
      )

      # perform sanity checks
      check_email_address_for_domain(
        email: @_params[:address],
        domain_id: @_params[:domain_id]
      )

      @mailsource = MailSource.new(@_params)
      if @mailsource.save
        @result = ApiResponseSuccess.new(status_code: 201,
                                         data: { object: @mailsource })
        response.headers['Location'] = [request.base_url,
                                        'api',
                                        'v1',
                                        'mailsources',
                                        @mailsource.id].join('/')
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
      if MailSource.first(address: @_params[:address]).nil?
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
    @mailsource = MailSource.get(params[:id])
    return_apiresponse(
      ApiResponseError.new(status_code: 404,
                           error_id: 'not found',
                           message: 'requested resource does not exist')
    ) if @mailsource.nil?
  end

  namespace '/:id' do
    delete do
      @result = nil

      # prevent any action being performed on a detroyed resource
      return_apiresponse(
        ApiResponseError.new(status_code: 500,
                             error_id: 'could not delete',
                             message: $ERROR_INFO.to_s)
      ) if @mailsource.destroyed?

      # check creation permissions. i.e. admin/quotacheck
      authorize(@mailsource, :destroy?)

      begin
        @result = if @mailsource.destroy
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
      authorize(@mailsource, :update?)

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
        ) if @mailsource.destroyed?

        # email addr must not be nil
        raise(ArgumentError, 'invalid email address') if @_params[:address].nil?

        # force lowercase on email addr
        @_params[:address].downcase!

        # check permissions for parameters
        raise Pundit::NotAuthorizedError unless policy(
          @mailsource
        ).update_with?(
          @_params
        )

        # perform sanity checks
        check_email_address_for_domain(
          email: @_params[:address],
          domain_id: @mailsource.domain_id
        )

        @result = if @mailsource.update(@_params)
                    ApiResponseSuccess.new(data: { object: @mailsource })
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
        if MailSource.first(address: @_params[:address]).nil?
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
      return_authorized_resource(object: @mailsource) if authorize(
        @mailsource,
        :show?
      )
    end
  end
end
