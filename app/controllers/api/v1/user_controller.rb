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
      # check for show errors request
      show_validation_errors = params.key?('validate')
      show_errors = params.key?('verbose')

      # get json data from request body and symbolize all keys
      request.body.rewind
      @_params = JSON.parse(request.body.read)
      @_params = symbolize_params_hash(@_params)

      if @_params[:packages].nil?
        # assign default packages which only has apikey quota
        @_params[:packages] = [Package.first(name: 'default').id]
      else
        # has to be an array if provided
        return_api_error(
          ApiErrors.[](:invalid_packages)
        ) unless @_params[:packages].is_a?(Array)
      end

      # check permissions for parameters
      raise Pundit::NotAuthorizedError unless policy(User).create_with?(
        @_params
      )

      # fetch packages as an array of mailaccounts
      unless @_params[:packages].nil?
        @packages = Package.all(id: 0)
        package_ids = @_params.delete(:packages)
        package_ids.each do |pkg_id|
          @packages.push(Package.get(pkg_id))
        end
        @_params[:packages] = @packages
      end

      # assign reseller
      @_params[:reseller_id] = @user.id if @user.reseller?

      # perform validations
      @_user = User.new(@_params)
      unless @_user.valid?
        errors = extract_object_errors(object: @_user)
        log_user('debug', "validation_errors: #{errors}")
        if show_validation_errors || show_errors
          return_api_error(ApiErrors.[](:invalid_request),
                           errors: { validation: errors })
        else
          return_api_error(ApiErrors.[](:invalid_request))
        end
      end

      if @_user.save
        log_user('info', "created User #{@_user.as_json}")
        @result = ApiResponseSuccess.new(status_code: 201,
                                         data: { object: @_user })
        loc = "#{request.base_url}/api/v1/users/#{@_user.id}"
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
    @_user = User.get(params[:id])
    return_api_error(ApiErrors.[](:not_found)) if @_user.nil?
  end

  namespace '/:id' do
    delete do
      @result = nil

      # check creation permissions. i.e. admin/quotacheck
      authorize(@_user, :destroy?)

      begin
        # check for show errors request
        show_errors = params.key?('verbose')

        @result = if @_user.destroy
                    log_user('info', "deleted User #{@_user.as_json}")
                    ApiResponseSuccess.new
                  elsif show_errors
                    errors = extract_destroy_errors(object: @_user)
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

      # check creation permissions. i.e. admin/quotacheck
      authorize(@_user, :update?)

      begin
        # check for show errors request
        show_validation_errors = params.key?('validate')
        show_errors = params.key?('verbose')

        # prevent any action being performed on a detroyed resource
        return_api_error(ApiErrors.[](:not_found)) if @_user.destroyed?

        # get json data from request body and symbolize all keys
        request.body.rewind
        @_params = JSON.parse(request.body.read)
        @_params = symbolize_params_hash(@_params)

        # has to be an array if provided
        unless @_params[:packages].nil?
          return_api_error(
            ApiErrors.[](:invalid_packages)
          ) unless @_params[:packages].is_a?(Array)
        end

        # check permissions for parameters
        raise Pundit::NotAuthorizedError unless policy(@_user).update_with?(
          @_params
        )

        # fetch packages as an array of mailaccounts
        unless @_params[:packages].nil?
          @packages = Package.all(id: 0)
          package_ids = @_params.delete(:packages)
          package_ids.each do |pkg_id|
            @packages.push(Package.get(pkg_id))
          end
          @_params[:packages] = @packages
        end

        # remove unmodified values from input params
        @_params.each_key do |key|
          next unless @_user.model.properties.map(&:name).include?(key)
          @_params.delete(key) if @_params[key] == @_user.send(key)
        end

        # perform validations on a dummy object, check only supplied attributes
        dummy = User.new(@_params)
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

        # remember old values for log message
        old_attributes = @_user.as_json

        if @_user.update(@_params)
          log_user('info', "updated User #{old_attributes} with #{@_params}")
          @result = ApiResponseSuccess.new(data: { object: @_user })
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
      return_authorized_resource(object: @_user) if authorize(@_user, :show?)
    end

    get '/enabled_modules' do
      return_apiresponse(
        ApiResponseSuccess.new(data: { object: settings.api_modules })
      )
    end

    get '/quota_stats' do
      quota_props = %w(apikeys)
      settings.api_modules.map(&:upcase).each do |apimod|
        case apimod
        when 'EMAIL' then quota_props.push(
          %w(domains mail_accounts mail_aliases mail_sources mail_forwardings
             mail_storage)
        )
        when 'VHOST' then quota_props.push(
          %w(domains vhosts vhost_storage sftp_users shell_users ssh_pubkeys)
        )
        when 'DNS' then quota_props.push(
          %w(domains dns_zones dns_records)
        )
        when 'DATABASE' then quota_props.push(
          %w(databases database_users)
        )
        end
      end

      quota_stats = {}
      quota_props.flatten.uniq.each do |prop|
        used = send("allocated_#{prop}", @_user)
        prop = "quota_#{prop}".to_sym
        total = @_user.packages.map(&prop).reduce(0, :+)
        quota_stats[prop] = {
          used: used,
          total: total
        }
      end

      return_apiresponse(
        ApiResponseSuccess.new(data: { object: quota_stats })
      )
    end
  end
end
