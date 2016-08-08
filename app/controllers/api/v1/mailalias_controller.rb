# frozen_string_literal: true
namespace '/api/v1/mailaliases' do
  get do
    @mailaliases = policy_scope(MailAlias)
    return_authorized_collection(object: @mailaliases, params: params)
  end

  post do
    @result = nil

    # check creation permissions. i.e. admin/quotacheck
    authorize(MailAlias, :create?)

    begin
      # get json data from request body and symbolize all keys
      request.body.rewind
      @_params = JSON.parse(request.body.read)
      @_params = symbolize_params_hash(@_params)

      # email addr must not be nil
      return_api_error(
        ApiErrors.[](:invalid_email)
      ) if @_params[:address].nil?

      # destinations must be an array
      if @_params[:dest].nil? || !@_params[:dest].is_a?(Array)
        return_api_error(ApiErrors.[](:invalid_alias_destinations))
      end

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

      # fetch destinations as an array of mailaccounts
      @destinations = MailAccount.all(id: 0)
      mailaccount_ids = @_params.delete(:dest)
      mailaccount_ids.each do |acc_id|
        @destinations.push(MailAccount.get(acc_id))
      end
      @_params[:mail_accounts] = @destinations

      @mailalias = MailAlias.new(@_params)
      if @mailalias.save
        @result = ApiResponseSuccess.new(status_code: 201,
                                         data: { object: @mailalias })
        loc = "#{request.base_url}/api/v1/mailaliases/#{@mailalias.id}"
        response.headers['Location'] = loc
      end
    rescue ArgumentError
      @result = api_error(ApiErrors.[](:invalid_request))
    rescue JSON::ParserError
      @result = api_error(ApiErrors.[](:malformed_request))
    rescue DataMapper::SaveFailureError
      @result = if MailAlias.first(address: @_params[:address]).nil?
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
    @mailalias = MailAlias.get(params[:id])
    return_api_error(ApiErrors.[](:not_found)) if @mailalias.nil?
  end

  namespace '/:id' do
    delete do
      @result = nil

      # prevent any action being performed on a detroyed resource
      return_api_error(ApiErrors.[](:failed_delete)) if @mailalias.destroyed?

      # check creation permissions. i.e. admin/quotacheck
      authorize(@mailalias, :destroy?)

      begin
        @result = if @mailalias.destroy
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
      authorize(@mailalias, :update?)

      begin
        # get json data from request body and symbolize all keys
        request.body.rewind
        @_params = JSON.parse(request.body.read)
        @_params = symbolize_params_hash(@_params)

        # prevent any action being performed on a detroyed resource
        return_api_error(ApiErrors.[](:failed_update)) if @mailalias.destroyed?

        if @_params.key?(:address)
          # email addr must not be nil
          return_api_error(
            ApiErrors.[](:invalid_email)
          ) if @_params[:address].nil?

          # force lowercase on email addr
          @_params[:address].downcase!

          # perform sanity checks
          check_email_address_for_domain(
            email: @_params[:address],
            domain_id: @mailalias.domain_id
          )
        end

        if @_params.key?(:dest)
          # destinations must be an array
          if @_params[:dest].nil? || !@_params[:dest].is_a?(Array)
            return_api_error(ApiErrors.[](:invalid_alias_destinations))
          end
        end

        # check permissions for parameters
        raise Pundit::NotAuthorizedError unless policy(
          @mailalias
        ).update_with?(
          @_params
        )

        if @_params.key?(:dest)
          # fetch destinations as an array of mailaccounts
          @destinations = MailAccount.all(id: 0)
          mailaccount_ids = @_params.delete(:dest)
          mailaccount_ids.each do |acc_id|
            @destinations.push(MailAccount.get(acc_id))
          end
          @_params[:mail_accounts] = @destinations
        end

        @result = if @mailalias.update(@_params)
                    ApiResponseSuccess.new(data: { object: @mailalias })
                  else
                    api_error(ApiErrors.[](:failed_update))
                  end
      rescue ArgumentError
        @result = api_error(ApiErrors.[](:invalid_request))
      rescue JSON::ParserError
        @result = api_error(ApiErrors.[](:malformed_request))
      rescue DataMapper::SaveFailureError
        @result = if MailAlias.first(address: @_params[:address]).nil?
                    api_error(ApiErrors.[](:failed_update))
                  else
                    api_error(ApiErrors.[](:resource_conflict))
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
