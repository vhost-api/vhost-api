# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
namespace '/api/v1/apikeys' do
  get do
    @apikeys = policy_scope(Apikey)
    return_authorized_collection(object: @apikeys, params: params)
  end

  post do
    @result = nil

    # check creation permissions. i.e. admin/quotacheck
    authorize(Apikey, :create?)

    begin
      # check for show errors request
      show_validation_errors = params.key?('validate')
      show_errors = params.key?('verbose')

      # get json data from request body and symbolize all keys
      request.body.rewind
      @_params = JSON.parse(request.body.read)
      @_params = symbolize_params_hash(@_params)

      # generate fresh apikey if nil, otherwise hash provided key
      if @_params[:apikey].nil?
        @plain = SecureRandom.hex(32)
      else
        @plain = @_params[:apikey]
        # if apikey was provided it has to be 64 characters long
        return_api_error(ApiErrors.[](:apikey_length)) if @plain.length != 64
      end
      @_params[:apikey] = Digest::SHA512.hexdigest(@plain)

      @apikey = Apikey.new(@_params)
      unless @apikey.valid?
        errors = extract_object_errors(object: @apikey)
        log_user('debug', "validation_errors: #{errors}")
        if show_validation_errors || show_errors
          return_api_error(ApiErrors.[](:invalid_request),
                           errors: { validation: errors })
        else
          return_api_error(ApiErrors.[](:invalid_request))
        end
      end

      # check permissions for parameters
      raise Pundit::NotAuthorizedError unless policy(Apikey).create_with?(
        @_params
      )

      if @apikey.save
        apikey_hash = @apikey.as_json
        log_user('info', "created Apikey #{apikey_hash}")
        # return plain apikey just this once after creation and do not log it
        apikey_hash[:apikey] = @plain
        @result = ApiResponseSuccess.new(status_code: 201,
                                         data: { object: apikey_hash })
        loc = "#{request.base_url}/api/v1/apikeys/#{@apikey.id}"
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
    rescue Error => err
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
    @apikey = Apikey.get(params[:id])
    return_api_error(ApiErrors.[](:not_found)) if @apikey.nil?
  end

  namespace '/:id' do
    delete do
      @result = nil

      # check creation permissions. i.e. admin/quotacheck
      authorize(@apikey, :destroy?)

      begin
        # check for show errors request
        show_errors = params.key?('verbose')

        # prevent any action being performed on a detroyed resource
        return_api_error(ApiErrors.[](:not_found)) if @apikey.destroyed?

        @result = if @apikey.destroy
                    log_user('info', "deleted Apikey #{@apikey.as_json}")
                    ApiResponseSuccess.new
                  elsif show_errors
                    errors = extract_destroy_errors(object: @apikey)
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
      authorize(@apikey, :update?)

      begin
        # check for show errors request
        show_validation_errors = params.key?('validate')
        show_errors = params.key?('verbose')

        # prevent any action being performed on a detroyed resource
        return_api_error(ApiErrors.[](:not_found)) if @apikey.destroyed?

        # get json data from request body and symbolize all keys
        request.body.rewind
        @_params = JSON.parse(request.body.read)
        @_params = symbolize_params_hash(@_params)

        # remove unmodified values from input params
        @_params.each_key do |key|
          next unless @apikey.model.properties.map(&:name).include?(key)
          @_params.delete(key) if @_params[key] == @apikey.send(key)
        end

        # if apikey was provided it has to be 64 characters long
        if @_params.key?(:apikey)
          if @_params[:apikey].nil?
            return_api_error(
              ApiErrors.[](:invalid_apikey)
            )
          end

          if @_params[:apikey].length < 64
            return_api_error(
              ApiErrors.[](:apikey_length)
            )
          end

          # hash the input plain text
          @_params[:apikey] = Digest::SHA512.hexdigest(@_params[:apikey])
        end

        # perform validations on a dummy object, check only supplied attributes
        dummy = Apikey.new(@_params)
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

        # check permissions for parameters
        raise Pundit::NotAuthorizedError unless policy(@apikey).update_with?(
          @_params
        )

        # remember old values for log message
        old_attributes = @apikey.as_json

        if @apikey.update(@_params)
          log_user('info', "updated Apikey #{old_attributes} with #{@_params}")
          @result = ApiResponseSuccess.new(data: { object: @apikey })
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
      rescue Error => err
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
      return_authorized_resource(object: @apikey) if authorize(@apikey, :show?)
    end

    post '/regenerate' do
      apikey = SecureRandom.hex(32)
      params = { apikey: apikey }
      status, headers, body = call(
        env.merge('REQUEST_METHOD' => 'PATCH',
                  'PATH_INFO' => "/api/v1/apikeys/#{@apikey.id}",
                  'rack.input' => StringIO.new(params.to_json),
                  'rack.request.form_hash' => nil,
                  'rack.request.form_vars' => nil)
      )
      status status
      headers headers
      # body seems to be wrapped in an array
      body_hash = JSON.parse(body[0])
      # include apikey plaintext in this once response
      if body_hash['status'] == 'success'
        body_hash['data']['object']['apikey'] = apikey
      end
      return_json_pretty(body_hash.to_json)
    end
  end
end
# rubocop:enable Metrics/BlockLength
