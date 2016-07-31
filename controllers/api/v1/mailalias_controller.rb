# frozen_string_literal: true
namespace '/api/v1/mailaliases' do
  helpers do
    def fetch_scoped_mailaliases
      @mailaliases = policy_scope(MailAlias)
    end
  end

  get do
    fetch_scoped_mailaliases
    return_authorized_collection(object: @mailaliases)
  end

  post do
    @result = nil

    # check creation permissions. i.e. admin/quotacheck
    authorize(MailAlias, :create?)

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
      raise Pundit::NotAuthorizedError unless policy(MailAlias).create_with?(
        @_params
      )

      # perform sanity checks
      check_email_address_for_domain(
        email: @_params[:address],
        domain_id: @_params[:domain_id]
      )

      @mailalias = MailAlias.new(@_params)
      if @mailalias.save
        @result = ApiResponseSuccess.new(status_code: 201,
                                         data: { object: @mailalias })
        response.headers['Location'] = [request.base_url,
                                        'api',
                                        'v1',
                                        'mailaliases',
                                        @mailalias.id].join('/')
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
      if MailAlias.first(address: @_params[:address]).nil?
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
    @mailalias = MailAlias.get(params[:id])
    return_apiresponse(
      ApiResponseError.new(status_code: 404,
                           error_id: 'not found',
                           message: 'requested resource does not exist')
    ) if @mailalias.nil?
  end

  namespace '/:id' do
    delete do
      @result = nil

      # prevent any action being performed on a detroyed resource
      return_apiresponse(
        ApiResponseError.new(status_code: 500,
                             error_id: 'could not delete',
                             message: $ERROR_INFO.to_s)
      ) if @mailalias.destroyed?

      # check creation permissions. i.e. admin/quotacheck
      authorize(@mailalias, :destroy?)

      begin
        @result = if @mailalias.destroy
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
      authorize(@mailalias, :update?)

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
        ) if @mailalias.destroyed?

        # email addr must not be nil
        raise(ArgumentError, 'invalid email address') if @_params[:address].nil?

        # force lowercase on email addr
        @_params[:address].downcase!

        # check permissions for parameters
        raise Pundit::NotAuthorizedError unless policy(
          @mailalias
        ).update_with?(
          @_params
        )

        # perform sanity checks
        check_email_address_for_domain(
          email: @_params[:address],
          domain_id: @mailalias.domain_id
        )

        @result = if @mailalias.update(@_params)
                    ApiResponseSuccess.new(data: { object: @mailalias })
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
        if MailAlias.first(address: @_params[:address]).nil?
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
      return_authorized_resource(object: @mailalias) if authorize(
        @mailalias,
        :show?
      )
    end
  end
end
