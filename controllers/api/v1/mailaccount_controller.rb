# frozen_string_literal: true
namespace '/api/v1/mailaccounts' do
  helpers do
    def fetch_scoped_mailaccounts
      @mailaccounts = policy_scope(MailAccount)
    end
  end

  get do
    fetch_scoped_mailaccounts
    return_authorized_collection(object: @mailaccounts)
  end

  post do
    @result = nil

    # check creation permissions. i.e. admin/quotacheck
    authorize(MailAccount, :create?)

    begin
      # get json data from request body and symbolize all keys
      request.body.rewind
      @_params = JSON.parse(request.body.read)
      @_params = @_params.reduce({}) do |memo, (k, v)|
        memo.tap { |m| m[k.to_sym] = v }
      end

      # generate dovecot password hash from plaintex
      @_params[:password] = gen_doveadm_pwhash(@_params[:password].to_s)

      # check permissions for parameters
      raise Pundit::NotAuthorizedError unless policy(MailAccount).create_with?(
        @_params
      )

      @mailaccount = MailAccount.new(@_params)
      if @mailaccount.save
        @result = ApiResponseSuccess.new(status_code: 201,
                                         data: { object: @mailaccount })
        response.headers['Location'] = [request.base_url,
                                        'api',
                                        'v1',
                                        'mailaccounts',
                                        @mailaccount.id].join('/')
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
      if MailAccount.first(email: @_params[:email]).nil?
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
    @mailaccount = MailAccount.get(params[:id])
    return_apiresponse(
      ApiResponseError.new(status_code: 404,
                           error_id: 'not found',
                           message: 'requested resource does not exist')
    ) if @mailaccount.nil?
  end

  namespace '/:id' do
    delete do
      @result = nil

      # prevent any action being performed on a detroyed resource
      return_apiresponse(
        ApiResponseError.new(status_code: 500,
                             error_id: 'could not delete',
                             message: $ERROR_INFO.to_s)
      ) if @mailaccount.destroyed?

      # check creation permissions. i.e. admin/quotacheck
      authorize(@mailaccount, :destroy?)

      begin
        @result = if @mailaccount.destroy
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
      authorize(@mailaccount, :update?)

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
        ) if @mailaccount.destroyed?

        # generate dovecot password hash from plaintex
        @_params[:password] = gen_doveadm_pwhash(@_params[:password].to_s)

        # check permissions for parameters
        raise Pundit::NotAuthorizedError unless policy(
          @mailaccount
        ).update_with?(
          @_params
        )

        @result = if @mailaccount.update(@_params)
                    ApiResponseSuccess.new(data: { object: @mailaccount })
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
        if MailAccount.first(email: @_params[:email]).nil?
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
      return_authorized_resource(object: @mailaccount) if authorize(
        @mailaccount,
        :show?
      )
    end
  end
end
