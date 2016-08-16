# frozen_string_literal: true
namespace '/api/v1/users' do
  get do
    @users = policy_scope(User)
    return_authorized_collection(object: @users, params: params)
  end

  post do
    @result = nil

    # check creation permissions. i.e. admin/quotacheck
    authorize(User, :create?)

    begin
      # get json data from request body and symbolize all keys
      request.body.rewind
      @_params = JSON.parse(request.body.read)
      @_params = symbolize_params_hash(@_params)

      # perform validations
      @_user = User.new(@_params)
      unless @_user.valid?
        errors = extract_object_errors(object: @_user)
        log_user('debug', "validation_errors: #{errors}")
        if settings.return_validation_errors
          return_api_error(ApiErrors.[](:invalid_request),
                           errors: { validation: errors })
        else
          return_api_error(ApiErrors.[](:invalid_request))
        end
      end

      # check permissions for parameters
      raise Pundit::NotAuthorizedError unless policy(User).create_with?(
        @_params
      )

      if @_user.save
        @result = ApiResponseSuccess.new(status_code: 201,
                                         data: { object: @_user })
        loc = [request.base_url, 'api', 'v1', 'users', @_user.id].join('/')
        response.headers['Location'] = loc
      end
    rescue ArgumentError => err
      log_user('debug', err.message)
      @result = api_error(ApiErrors.[](:invalid_request))
    rescue JSON::ParserError => err
      log_user('debug', err.message)
      @result = api_error(ApiErrors.[](:malformed_request))
    rescue DataMapper::SaveFailureError => err
      log_user('debug', err.message)
      @result = if User.first(login: @_params[:login]).nil?
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
    @_user = User.get(params[:id])
    return_api_error(ApiErrors.[](:not_found)) if @_user.nil?
  end

  namespace '/:id' do
    delete do
      @result = nil

      # check creation permissions. i.e. admin/quotacheck
      authorize(@_user, :destroy?)

      begin
        @result = if @_user.destroy
                    ApiResponseSuccess.new
                  elsif settings.return_validation_errors
                    api_error(
                      ApiErrors.[](:failed_delete),
                      errors: { details: @_user.errors.full_messages }
                    )
                  else
                    api_error(ApiErrors.[](:failed_delete))
                  end
      end
      return_apiresponse @result
    end

    patch do
      @result = nil

      # check creation permissions. i.e. admin/quotacheck
      authorize(@_user, :update?)

      begin
        # get json data from request body and symbolize all keys
        request.body.rewind
        @_params = JSON.parse(request.body.read)
        @_params = symbolize_params_hash(@_params)

        # perform validations on a dummy object, check only supplied attributes
        dummy = User.new(@_params)
        unless dummy.valid?
          error_attributes = @_params.keys & dummy.errors.keys
          unless error_attributes.empty?
            # extract only relevant errors for @_params
            errors = extract_selected_errors(object: dummy,
                                             selected: error_attributes)

            log_user('debug', "validation_errors: #{errors}")
            if settings.return_validation_errors
              return_api_error(ApiErrors.[](:invalid_request),
                               errors: { validation: errors })
            else
              return_api_error(ApiErrors.[](:invalid_request))
            end
          end
        end

        # check permissions for parameters
        raise Pundit::NotAuthorizedError unless policy(@_user).update_with?(
          @_params
        )

        @result = if @_user.update(@_params)
                    ApiResponseSuccess.new(data: { object: @_user })
                  else
                    errors = extract_object_errors(object: @_user)
                    log_user('debug', "validation_errors: #{errors}")
                    if settings.return_validation_errors
                      return_api_error(ApiErrors.[](:failed_update),
                                       errors: { validation: errors })
                    else
                      return_api_error(ApiErrors.[](:failed_update))
                    end
                  end
      rescue ArgumentError => err
        log_user('debug', err.message)
        @result = api_error(ApiErrors.[](:invalid_request))
      rescue JSON::ParserError => err
        log_user('debug', err.message)
        @result = api_error(ApiErrors.[](:malformed_request))
      rescue DataMapper::SaveFailureError => err
        log_user('debug', err.message)
        @result = if User.first(login: @_params[:login]).nil?
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

    get do
      return_authorized_resource(object: @_user) if authorize(@_user, :show?)
    end

    get '/enabled_modules' do
      return_json_pretty(settings.api_modules.to_json)
    end
  end
end
