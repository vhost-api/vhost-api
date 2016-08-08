# frozen_string_literal: true
namespace '/api/v1/mailaccounts' do
  get do
    @mailaccounts = policy_scope(MailAccount)
    return_authorized_collection(object: @mailaccounts, params: params)
  end

  post do
    @result = nil

    # check creation permissions. i.e. admin/quotacheck
    authorize(MailAccount, :create?)

    begin
      # get json data from request body and symbolize all keys
      request.body.rewind
      @_params = JSON.parse(request.body.read)
      @_params = symbolize_params_hash(@_params)

      # email addr must not be nil
      return_api_error(ApiErrors.[](:invalid_email)) if @_params[:email].nil?

      # password must not be nil
      return_api_error(
        ApiErrors.[](:password_required)
      ) if @_params[:password].nil?

      # generate dovecot password hash from plaintex
      @_params[:password] = gen_doveadm_pwhash(@_params[:password].to_s)

      # force lowercase on email addr
      @_params[:email].downcase!

      # check permissions for parameters
      raise Pundit::NotAuthorizedError unless policy(MailAccount).create_with?(
        @_params
      )

      # perform sanity checks
      check_email_address_for_domain(
        email: @_params[:email],
        domain_id: @_params[:domain_id]
      )

      @mailaccount = MailAccount.new(@_params)
      if @mailaccount.save
        @result = ApiResponseSuccess.new(status_code: 201,
                                         data: { object: @mailaccount })
        loc = "#{request.base_url}/api/v1/mailaccounts/#{@mailaccount.id}"
        response.headers['Location'] = loc
      end
    rescue ArgumentError
      @result = api_error(ApiErrors.[](:invalid_request))
    rescue JSON::ParserError
      @result = api_error(ApiErrors.[](:malformed_request))
    rescue DataMapper::SaveFailureError
      @result = if MailAccount.first(email: @_params[:email]).nil?
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
    @mailaccount = MailAccount.get(params[:id])
    return_api_error(ApiErrors.[](:not_found)) if @mailaccount.nil?
  end

  namespace '/:id' do
    delete do
      @result = nil

      # prevent any action being performed on a detroyed resource
      return_api_error(ApiErrors.[](:failed_delete)) if @mailaccount.destroyed?

      # check creation permissions. i.e. admin/quotacheck
      authorize(@mailaccount, :destroy?)

      begin
        @result = if @mailaccount.destroy
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
      authorize(@mailaccount, :update?)

      begin
        # get json data from request body and symbolize all keys
        request.body.rewind
        @_params = JSON.parse(request.body.read)
        @_params = symbolize_params_hash(@_params)

        # prevent any action being performed on a detroyed resource
        return_api_error(
          ApiErrors.[](:failed_update)
        ) if @mailaccount.destroyed?

        # generate dovecot password hash from plaintex
        unless @_params[:password].nil?
          @_params[:password] = gen_doveadm_pwhash(@_params[:password].to_s)
        end

        if @_params.key?(:email)
          # email addr must not be nil
          return_api_error(
            ApiErrors.[](:invalid_email)
          ) if @_params[:email].nil?

          # force lowercase on email addr
          @_params[:email].downcase!

          # perform sanity checks
          check_email_address_for_domain(
            email: @_params[:email],
            domain_id: @mailaccount.domain_id
          )
        end

        # check permissions for parameters
        raise Pundit::NotAuthorizedError unless policy(
          @mailaccount
        ).update_with?(
          @_params
        )

        @result = if @mailaccount.update(@_params)
                    ApiResponseSuccess.new(data: { object: @mailaccount })
                  else
                    api_error(ApiErrors.[](:failed_update))
                  end
      rescue ArgumentError
        @result = api_error(ApiErrors.[](:invalid_request))
      rescue JSON::ParserError
        @result = api_error(ApiErrors.[](:malformed_request))
      rescue DataMapper::SaveFailureError
        @result = if MailAccount.first(email: @_params[:email]).nil?
                    api_error(ApiErrors.[](:failed_update))
                  else
                    api_error(ApiErrors.[](:resource_conflict))
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
