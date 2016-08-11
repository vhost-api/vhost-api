# frozen_string_literal: true
namespace '/api/v1/mailsources' do
  get do
    @mailsources = policy_scope(MailSource)
    return_authorized_collection(object: @mailsources, params: params)
  end

  post do
    @result = nil

    # check creation permissions. i.e. admin/quotacheck
    authorize(MailSource, :create?)

    begin
      # get json data from request body and symbolize all keys
      request.body.rewind
      @_params = JSON.parse(request.body.read)
      @_params = symbolize_params_hash(@_params)

      # email addr must not be nil
      return_api_error(
        ApiErrors.[](:invalid_email)
      ) if @_params[:address].nil?

      # sources must be an Array
      if @_params[:src].nil? || !@_params[:src].is_a?(Array)
        return_api_error(ApiErrors.[](:invalid_sources))
      end

      # force lowercase on email addr
      @_params[:address].downcase!

      # perform sanity checks
      check_email_address_for_domain(
        email: @_params[:address],
        domain_id: @_params[:domain_id]
      )

      # check permissions for parameters
      raise Pundit::NotAuthorizedError unless policy(MailSource).create_with?(
        @_params
      )

      # fetch sources as an array of mailaccounts
      @sources = MailAccount.all(id: 0)
      mailaccount_ids = @_params.delete(:src)
      mailaccount_ids.each do |acc_id|
        @sources.push(MailAccount.get(acc_id))
      end
      @_params[:mail_accounts] = @sources

      @mailsource = MailSource.new(@_params)
      if @mailsource.save
        @result = ApiResponseSuccess.new(status_code: 201,
                                         data: { object: @mailsource })
        loc = "#{request.base_url}/api/v1/mailsources/#{@mailsource.id}"
        response.headers['Location'] = loc
      end
    rescue ArgumentError
      @result = api_error(ApiErrors.[](:invalid_request))
    rescue JSON::ParserError
      @result = api_error(ApiErrors.[](:malformed_request))
    rescue DataMapper::SaveFailureError
      @result = if MailSource.first(address: @_params[:address]).nil?
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
    @mailsource = MailSource.get(params[:id])
    return_api_error(ApiErrors.[](:not_found)) if @mailsource.nil?
  end

  namespace '/:id' do
    delete do
      @result = nil

      # prevent any action being performed on a detroyed resource
      return_api_error(ApiErrors.[](:failed_delete)) if @mailsource.destroyed?

      # check creation permissions. i.e. admin/quotacheck
      authorize(@mailsource, :destroy?)

      begin
        @result = if @mailsource.destroy
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
      authorize(@mailsource, :update?)

      begin
        # get json data from request body and symbolize all keys
        request.body.rewind
        @_params = JSON.parse(request.body.read)
        @_params = symbolize_params_hash(@_params)

        # prevent any action being performed on a detroyed resource
        return_api_error(ApiErrors.[](:failed_update)) if @mailsource.destroyed?

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
            domain_id: @mailsource.domain_id
          )
        end

        if @_params.key?(:src)
          # sources must be an Array
          if @_params[:src].nil? || !@_params[:src].is_a?(Array)
            return_api_error(ApiErrors.[](:invalid_sources))
          end
        end

        # check permissions for parameters
        raise Pundit::NotAuthorizedError unless policy(
          @mailsource
        ).update_with?(
          @_params
        )

        if @_params.key?(:src)
          # fetch sources as an array of mailaccounts
          @sources = MailAccount.all(id: 0)
          mailaccount_ids = @_params.delete(:src)
          mailaccount_ids.each do |acc_id|
            @sources.push(MailAccount.get(acc_id))
          end
          @_params[:mail_accounts] = @sources
        end

        @result = if @mailsource.update(@_params)
                    ApiResponseSuccess.new(data: { object: @mailsource })
                  else
                    api_error(ApiErrors.[](:failed_update))
                  end
      rescue ArgumentError
        @result = api_error(ApiErrors.[](:invalid_request))
      rescue JSON::ParserError
        @result = api_error(ApiErrors.[](:malformed_request))
      rescue DataMapper::SaveFailureError
        @result = if MailSource.first(address: @_params[:address]).nil?
                    api_error(ApiErrors.[](:failed_update))
                  else
                    api_error(ApiErrors.[](:resource_conflict))
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
