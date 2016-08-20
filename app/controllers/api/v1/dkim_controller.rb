# frozen_string_literal: true
namespace '/api/v1/dkims' do
  helpers do
    # @return [String, String]
    def generate_dkim_keypair
      keypair = SSHKey.generate(
        type: 'RSA',
        bits: settings.dkim_keysize_default,
        comment: nil,
        passphrase: nil
      )
      [keypair.private_key, keypair.public_key]
    end
  end
  get do
    @dkims = policy_scope(Dkim)
    return_authorized_collection(object: @dkims, params: params)
  end

  post do
    @result = nil

    # check creation permissions. i.e. admin/quotacheck
    authorize(Dkim, :create?)

    begin
      # check for show errors request
      show_validation_errors = params.key?('validate')
      show_errors = params.key?('verbose')

      # get json data from request body and symbolize all keys
      request.body.rewind
      @_params = JSON.parse(request.body.read)
      @_params = symbolize_params_hash(@_params)

      # force lowercase on selector
      @_params[:selector].downcase! unless @_params[:selector].nil?

      # require both or none of the keys (XOR)
      if @_params[:private_key].nil? ^ @_params[:public_key].nil?
        return_api_error(ApiErrors.[](:invalid_dkim_keypair))
      end

      # generate new keypar if nothing provided in request
      if @_params[:private_key].nil? && @_params[:public_key].nil?
        @_params[:private_key], @_params[:public_key] = generate_dkim_keypair
      end

      # perform validations
      @dkim = Dkim.new(@_params)
      unless @dkim.valid?
        errors = extract_object_errors(object: @dkim)
        log_user('debug', "validation_errors: #{errors}")
        if show_validation_errors || show_errors
          return_api_error(ApiErrors.[](:invalid_request),
                           errors: { validation: errors })
        else
          return_api_error(ApiErrors.[](:invalid_request))
        end
      end

      # check permissions for parameters
      raise Pundit::NotAuthorizedError unless policy(Dkim).create_with?(
        @_params
      )

      if @dkim.save
        log_user('info', "created Dkim #{@dkim.as_json}")
        @result = ApiResponseSuccess.new(status_code: 201,
                                         data: { object: @dkim })
        loc = "#{request.base_url}/api/v1/dkims/#{@dkim.id}"
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
      errors = extract_object_errors(object: @dkim)
      log_user('debug', "create_errors: #{errors}")
      @result = if show_validation_errors || show_errors
                  api_error(ApiErrors.[](:failed_create),
                            errors: errors)
                else
                  api_error(ApiErrors.[](:failed_create))
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
    @dkim = Dkim.get(params[:id])
    return_api_error(ApiErrors.[](:not_found)) if @dkim.nil?
  end

  namespace '/:id' do
    delete do
      @result = nil

      # check creation permissions. i.e. admin/quotacheck
      authorize(@dkim, :destroy?)

      begin
        # check for show errors request
        show_errors = params.key?('verbose')

        # prevent any action being performed on a detroyed resource
        return_api_error(ApiErrors.[](:not_found)) if @dkim.destroyed?

        @result = if @dkim.destroy
                    log_user('info', "deleted Dkim #{@dkim.as_json}")
                    ApiResponseSuccess.new
                  elsif show_errors
                    errors = extract_destroy_errors(object: @dkim)
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
      authorize(@dkim, :update?)

      begin
        # check for show errors request
        show_validation_errors = params.key?('validate')
        show_errors = params.key?('verbose')

        # prevent any action being performed on a detroyed resource
        return_api_error(ApiErrors.[](:not_found)) if @dkim.destroyed?

        # get json data from request body and symbolize all keys
        request.body.rewind
        @_params = JSON.parse(request.body.read)
        @_params = symbolize_params_hash(@_params)

        # force lowercase on selector
        @_params[:selector].downcase! unless @_params[:selector].nil?

        # require both or none of the keys (XOR)
        if @_params[:private_key].nil? ^ @_params[:public_key].nil?
          return_api_error(ApiErrors.[](:invalid_dkim_keypair_update))
        end

        # remove unmodified values from input params
        @_params.each_key do |key|
          next unless @dkim.model.properties.map(&:name).include?(key)
          @_params.delete(key) if @_params[key] == @dkim.send(key)
        end

        # perform validations on a dummy object, check only supplied attributes
        dummy = Dkim.new(@_params)
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
        raise Pundit::NotAuthorizedError unless policy(@dkim).update_with?(
          @_params
        )

        # remember old values for log message
        old_attributes = @dkim.as_json

        if @dkim.update(@_params)
          log_user('info', "updated Dkim #{old_attributes} with #{@_params}")
          @result = ApiResponseSuccess.new(data: { object: @dkim })
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
        errors = extract_object_errors(object: @dkim)
        log_user('debug', "update_errors: #{errors}")
        @result = if show_validation_errors || show_errors
                    api_error(ApiErrors.[](:failed_update),
                              errors: errors)
                  else
                    api_error(ApiErrors.[](:failed_update))
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
      return_authorized_resource(object: @dkim) if authorize(@dkim, :show?)
    end

    post '/regenerate' do
      privkey, pubkey = generate_dkim_keypair
      key_params = { private_key: privkey, public_key: pubkey }
      status, headers, body = call(
        env.merge('REQUEST_METHOD' => 'PATCH',
                  'PATH_INFO' => "/api/v1/dkims/#{@dkim.id}",
                  'rack.input' => StringIO.new(key_params.to_json),
                  'rack.request.form_hash' => nil,
                  'rack.request.form_vars' => nil)
      )
      [status, headers, body]
    end
  end
end
