# frozen_string_literal: true

namespace '/api/v1/dkimsignings' do
  get do
    @dkimsignings = policy_scope(DkimSigning)
    return_authorized_collection(object: @dkimsignings, params: params)
  end

  post do
    @result = nil

    # check creation permissions. i.e. admin/quotacheck
    authorize(DkimSigning, :create?)

    begin
      # check for show errors request
      show_validation_errors = params.key?('validate')
      show_errors = params.key?('verbose')

      # get json data from request body and symbolize all keys
      request.body.rewind
      @_params = JSON.parse(request.body.read)
      @_params = symbolize_params_hash(@_params)

      # force lowercase on author
      @_params[:author]&.downcase!

      # perform validations
      @dkimsigning = DkimSigning.new(@_params)
      unless @dkimsigning.valid?
        errors = extract_object_errors(object: @dkimsigning)
        log_user('debug', "validation_errors: #{errors}")
        if show_validation_errors || show_errors
          return_api_error(ApiErrors.[](:invalid_request),
                           errors: { validation: errors })
        else
          return_api_error(ApiErrors.[](:invalid_request))
        end
      end

      # perform sanity checks
      check_dkim_author_for_dkim(
        author: @_params[:author],
        dkim_id: @_params[:dkim_id]
      )

      # check permissions for parameters
      raise Pundit::NotAuthorizedError unless policy(DkimSigning).create_with?(
        @_params
      )

      if @dkimsigning.save
        log_user('info', "created DkimSigning #{@dkimsigning.as_json}")
        @result = ApiResponseSuccess.new(status_code: 201,
                                         data: { object: @dkimsigning })
        loc = "#{request.base_url}/api/v1/dkimsignings/#{@dkimsigning.id}"
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
    @dkimsigning = DkimSigning.get(params[:id])
    return_api_error(ApiErrors.[](:not_found)) if @dkimsigning.nil?
  end

  namespace '/:id' do
    delete do
      @result = nil

      # check creation permissions. i.e. admin/quotacheck
      authorize(@dkimsigning, :destroy?)

      begin
        # check for show errors request
        show_errors = params.key?('verbose')

        # prevent any action being performed on a detroyed resource
        return_api_error(ApiErrors.[](:not_found)) if @dkimsigning.destroyed?

        @result = if @dkimsigning.destroy
                    log_user('info',
                             "deleted DkimSigning #{@dkimsigning.as_json}")
                    ApiResponseSuccess.new
                  elsif show_errors
                    errors = extract_destroy_errors(object: @dkimsigning)
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
      authorize(@dkimsigning, :update?)

      begin
        # check for show errors request
        show_validation_errors = params.key?('validate')
        show_errors = params.key?('verbose')

        # prevent any action being performed on a detroyed resource
        return_api_error(ApiErrors.[](:not_found)) if @dkimsigning.destroyed?

        # get json data from request body and symbolize all keys
        request.body.rewind
        @_params = JSON.parse(request.body.read)
        @_params = symbolize_params_hash(@_params)

        # force lowercase on author
        @_params[:author]&.downcase!

        # remove unmodified values from input params
        @_params.each_key do |key|
          next unless @dkimsigning.model.properties.map(&:name).include?(key)
          @_params.delete(key) if @_params[key] == @dkimsigning.send(key)
        end

        # perform validations on a dummy object, check only supplied attributes
        dummy = DkimSigning.new(@_params)
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

        # perform sanity checks
        unless @_params[:author].nil?
          check_dkim_author_for_dkim(
            author: @_params[:author],
            dkim_id: @dkimsigning.dkim_id
          )
        end

        # check permissions for parameters
        raise Pundit::NotAuthorizedError unless policy(
          @dkimsigning
        ).update_with?(@_params)

        # remember old values for log message
        old_attributes = @dkimsigning.as_json

        if @dkimsigning.update(@_params)
          log_user('info',
                   "updated DkimSigning #{old_attributes} with #{@_params}")
          @result = ApiResponseSuccess.new(data: { object: @dkimsigning })
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
      return_authorized_resource(object: @dkimsigning) if authorize(
        @dkimsigning,
        :show?
      )
    end
  end
end
