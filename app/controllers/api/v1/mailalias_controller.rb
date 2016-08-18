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
      # check for show errors request
      show_validation_errors = params.key?('validate')
      show_errors = params.key?('verbose')

      # get json data from request body and symbolize all keys
      request.body.rewind
      @_params = JSON.parse(request.body.read)
      @_params = symbolize_params_hash(@_params)

      # destinations must be an array if provided
      unless @_params[:dest].nil?
        return_api_error(
          ApiErrors.[](:invalid_alias_destinations)
        ) unless @_params[:dest].is_a?(Array)
      end

      # force lowercase on email addr
      @_params[:address].downcase! unless @_params[:address].nil?

      # check permissions for parameters
      raise Pundit::NotAuthorizedError unless policy(MailAlias).create_with?(
        @_params
      )

      # fetch destinations as an array of mailaccounts
      unless @_params[:dest].nil?
        @destinations = MailAccount.all(id: 0)
        mailaccount_ids = @_params.delete(:dest)
        mailaccount_ids.each do |acc_id|
          @destinations.push(MailAccount.get(acc_id))
        end
        @_params[:mail_accounts] = @destinations
      end

      # perform validations
      @mailalias = MailAlias.new(@_params)
      unless @mailalias.valid?
        errors = extract_object_errors(object: @mailalias)
        log_user('debug', "validation_errors: #{errors}")
        if show_validation_errors || show_errors
          return_api_error(ApiErrors.[](:invalid_request),
                           errors: { validation: errors })
        else
          return_api_error(ApiErrors.[](:invalid_request))
        end
      end

      # perform sanity checks
      check_email_address_for_domain(
        email: @_params[:address],
        domain_id: @_params[:domain_id]
      )

      if @mailalias.save
        log_user('info', "created MailAlias #{@mailalias.as_json}")
        @result = ApiResponseSuccess.new(status_code: 201,
                                         data: { object: @mailalias })
        loc = "#{request.base_url}/api/v1/mailaliases/#{@mailalias.id}"
        response.headers['Location'] = loc
      end
    # re-raise authentication/authorization errors so that they don't end up
    # in the last catchall
    rescue Pundit::NotAuthorizedError, AuthenticationError
      raise
    rescue ArgumentError => err
      log_user('debug', err.message)
      @result = if show_errors
                  api_error(ApiErrors.[](:invalid_request),
                            errors: { argument: err.message })
                else
                  api_error(ApiErrors.[](:invalid_request))
                end
    rescue JSON::ParserError => err
      log_user('debug', err.message)
      @result = if show_errors
                  api_error(ApiErrors.[](:malformed_request),
                            errors: { format: err.message })
                else
                  api_error(ApiErrors.[](:malformed_request))
                end
    rescue DataMapper::SaveFailureError => err
      log_user('debug', err.message)
      @result = if MailAccount.first(address: @_params[:address]).nil?
                  api_error(ApiErrors.[](:failed_create))
                else
                  api_error(ApiErrors.[](:resource_conflict))
                end
    rescue => err
      # unhandled error, always log backtrace
      log_user('error', err.message)
      log_user('error', err.backtrace.join("\n"))
      # print backtrace in api response only if we're in development env
      errors = if settings.environment == :development
                 { errors: [err.message, err.backtrace] }
               else
                 { errors: err.message }
               end
      @result = api_error(ApiErrors.[](:internal_error), errors)
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

      # check creation permissions. i.e. admin/quotacheck
      authorize(@mailalias, :destroy?)

      begin
        # check for show errors request
        show_errors = params.key?('verbose')

        # prevent any action being performed on a detroyed resource
        return_api_error(ApiErrors.[](:not_found)) if @mailalias.destroyed?

        @result = if @mailalias.destroy
                    log_user('info', "deleted MailAlias #{@mailalias.as_json}")
                    ApiResponseSuccess.new
                  elsif show_errors
                    errors = extract_destroy_errors(object: @mailalias)
                    api_error(
                      ApiErrors.[](:failed_delete),
                      errors: { relationships: errors }
                    )
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
        # check for show errors request
        show_validation_errors = params.key?('validate')
        show_errors = params.key?('verbose')

        # prevent any action being performed on a detroyed resource
        return_api_error(ApiErrors.[](:not_found)) if @mailalias.destroyed?

        # get json data from request body and symbolize all keys
        request.body.rewind
        @_params = JSON.parse(request.body.read)
        @_params = symbolize_params_hash(@_params)

        # prevent any action being performed on a detroyed resource
        return_api_error(ApiErrors.[](:failed_update)) if @mailalias.destroyed?

        unless @_params[:dest].nil?
          # destinations must be an array
          return_api_error(
            ApiErrors.[](:invalid_alias_destinations)
          ) unless @_params[:dest].is_a?(Array)
        end

        # check permissions for parameters
        raise Pundit::NotAuthorizedError unless policy(@mailalias).update_with?(
          @_params
        )

        # fetch destinations as an array of mailaccounts
        unless @_params[:dest].nil?
          @destinations = MailAccount.all(id: 0)
          mailaccount_ids = @_params.delete(:dest)
          mailaccount_ids.each do |acc_id|
            @destinations.push(MailAccount.get(acc_id))
          end
          @_params[:mail_accounts] = @destinations
        end

        # remove unmodified values from input params
        @_params.each_key do |key|
          next unless @mailalias.model.properties.map(&:name).include?(key)
          @_params.delete(key) if @_params[key] == @mailalias.send(key)
        end

        # perform validations on a dummy object, check only supplied attributes
        dummy = MailAlias.new(@_params)
        unless dummy.valid?
          error_attributes = @_params.keys & dummy.errors.keys
          unless error_attributes.empty?
            # extract only relevant errors for @_params
            errors = extract_selected_errors(object: dummy,
                                             selected: error_attributes)

            log_user('debug', "validation_errors: #{errors}")
            if show_validation_errors || show_errors
              return_api_error(ApiErrors.[](:invalid_request),
                               errors: { validation: errors })
            else
              return_api_error(ApiErrors.[](:invalid_request))
            end
          end
        end

        unless @_params[:address].nil?
          # force lowercase on email addr
          @_params[:address].downcase!

          # perform sanity checks
          check_email_address_for_domain(
            email: @_params[:address],
            domain_id: @mailalias.domain_id
          )
        end

        # remember old values for log message
        old_attributes = @mailalias.as_json

        if @mailalias.update(@_params)
          log_user('info',
                   "updated MailAlias #{old_attributes} with #{@_params}")
          @result = ApiResponseSuccess.new(data: { object: @domain })
        end

        @result = if @mailalias.update(@_params)
                    ApiResponseSuccess.new(data: { object: @mailalias })
                  else
                    api_error(ApiErrors.[](:failed_update))
                  end
      # re-raise authentication/authorization errors so that they don't end up
      # in the last catchall
      rescue Pundit::NotAuthorizedError, AuthenticationError
        raise
      rescue ArgumentError => err
        log_user('debug', err.message)
        @result = if show_errors
                    api_error(ApiErrors.[](:invalid_request),
                              errors: { argument: err.message })
                  else
                    api_error(ApiErrors.[](:invalid_request))
                  end
      rescue JSON::ParserError => err
        log_user('debug', err.message)
        @result = if show_errors
                    api_error(ApiErrors.[](:malformed_request),
                              errors: { format: err.message })
                  else
                    api_error(ApiErrors.[](:malformed_request))
                  end
      rescue DataMapper::SaveFailureError => err
        log_user('debug', err.message)
        @result = if MailAlias.first(address: @_params[:address]).nil?
                    api_error(ApiErrors.[](:failed_update))
                  else
                    api_error(ApiErrors.[](:resource_conflict))
                  end
      rescue => err
        # unhandled error, always log backtrace
        log_user('error', err.message)
        log_user('error', err.backtrace.join("\n"))
        # print backtrace in api response only if we're in development env
        errors = if settings.environment == :development
                   { errors: [err.message, err.backtrace] }
                 else
                   { errors: err.message }
                 end
        @result = api_error(ApiErrors.[](:internal_error), errors)
      end
      return_apiresponse @result
    end

    get do
      return_authorized_resource(object: @mailalias) if authorize(@mailalias,
                                                                  :show?)
    end
  end
end
