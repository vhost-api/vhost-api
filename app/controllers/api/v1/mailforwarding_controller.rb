# frozen_string_literal: true

namespace '/api/v1/mailforwardings' do
  get do
    @mailforwardings = policy_scope(MailForwarding)
    return_authorized_collection(object: @mailforwardings, params: params)
  end

  post do
    @result = nil

    # check creation permissions. i.e. admin/quotacheck
    authorize(MailForwarding, :create?)

    begin
      # check for show errors request
      show_validation_errors = params.key?('validate')
      show_errors = params.key?('verbose')

      # get json data from request body and symbolize all keys
      request.body.rewind
      @_params = JSON.parse(request.body.read)
      @_params = symbolize_params_hash(@_params)

      # force lowercase on email addr
      @_params[:address]&.downcase!
      @_params[:destinations]&.downcase!

      # remove any '\r', we only want '\n'
      @_params[:destinations]&.delete!("\r")

      # check permissions for parameters
      raise Pundit::NotAuthorizedError unless policy(
        MailForwarding
      ).create_with?(@_params)

      # perform validations
      @mailforwarding = MailForwarding.new(@_params)
      unless @mailforwarding.valid?
        errors = extract_object_errors(object: @mailforwarding)
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

      if @mailforwarding.save
        log_user('info', "created MailForwarding #{@mailforwarding.as_json}")
        @result = ApiResponseSuccess.new(status_code: 201,
                                         data: { object: @mailforwarding })
        loc = "#{request.base_url}/api/v1/mailforwardings/#{@mailforwarding.id}"
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
    @mailforwarding = MailForwarding.get(params[:id])
    return_api_error(ApiErrors.[](:not_found)) if @mailforwarding.nil?
  end

  namespace '/:id' do
    delete do
      @result = nil

      # check creation permissions. i.e. admin/quotacheck
      authorize(@mailforwarding, :destroy?)

      begin
        # check for show errors request
        show_errors = params.key?('verbose')

        # prevent any action being performed on a detroyed resource
        return_api_error(ApiErrors.[](:not_found)) if @mailforwarding.destroyed?

        @result = if @mailforwarding.destroy
                    log_user(
                      'info',
                      "deleted MailForwarding #{@mailforwarding.as_json}"
                    )
                    ApiResponseSuccess.new
                  elsif show_errors
                    errors = extract_destroy_errors(object: @mailforwarding)
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
      authorize(@mailforwarding, :update?)

      begin
        # check for show errors request
        show_validation_errors = params.key?('validate')
        show_errors = params.key?('verbose')

        # prevent any action being performed on a detroyed resource
        return_api_error(ApiErrors.[](:not_found)) if @mailforwarding.destroyed?

        # get json data from request body and symbolize all keys
        request.body.rewind
        @_params = JSON.parse(request.body.read)
        @_params = symbolize_params_hash(@_params)

        # force lowercase on email addr
        @_params[:address]&.downcase!
        @_params[:destinations]&.downcase!

        # remove any '\r', we only want '\n'
        @_params[:destinations]&.delete!("\r")

        # prevent any action being performed on a detroyed resource
        if @mailforwarding.destroyed?
          return_api_error(
            ApiErrors.[](:failed_update)
          )
        end

        # check permissions for parameters
        raise Pundit::NotAuthorizedError unless policy(
          @mailforwarding
        ).update_with?(@_params)

        # remove unmodified values from input params
        @_params.each_key do |key|
          next unless @mailforwarding.model.properties.map(&:name).include?(key)
          @_params.delete(key) if @_params[key] == @mailforwarding.send(key)
        end

        # perform validations on a dummy object, check only supplied attributes
        dummy = MailForwarding.new(@_params)
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
          # perform sanity checks
          check_email_address_for_domain(
            email: @_params[:address],
            domain_id: @mailforwarding.domain_id
          )
        end

        # remember old values for log message
        old_attributes = @mailforwarding.as_json

        if @mailforwarding.update(@_params)
          log_user('info',
                   "updated MailForwarding #{old_attributes} with #{@_params}")
          @result = ApiResponseSuccess.new(data: { object: @mailforwarding })
        end

        @result = if @mailforwarding.update(@_params)
                    ApiResponseSuccess.new(data: { object: @mailforwarding })
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
      return_authorized_resource(object: @mailforwarding) if authorize(
        @mailforwarding, :show?
      )
    end
  end
end
