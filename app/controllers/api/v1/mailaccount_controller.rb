# frozen_string_literal: true
namespace '/api/v1/mailaccounts' do
  helpers do
    # @return [String]
    def sieve_filename
      email_parts = @mailaccount.email.to_s.split('@')
      settings = Sinatra::Application.settings
      File.join(
        settings.mail_home,
        [email_parts[1], email_parts[0], settings.sieve_file].join('/')
      )
    end
  end

  get do
    @mailaccounts = policy_scope(MailAccount)
    return_authorized_collection(object: @mailaccounts, params: params)
  end

  post do
    @result = nil

    # check creation permissions. i.e. admin/quotacheck
    authorize(MailAccount, :create?)

    begin
      # check for show errors request
      show_validation_errors = params.key?('validate')
      show_errors = params.key?('verbose')

      # get json data from request body and symbolize all keys
      request.body.rewind
      @_params = JSON.parse(request.body.read)
      @_params = symbolize_params_hash(@_params)

      # force lowercase on email addr
      @_params[:email].downcase! unless @_params[:email].nil?

      # generate dovecot password hash from plaintex
      @_params[:password] = gen_doveadm_pwhash(
        @_params[:password].to_s
      ) unless @_params[:password].nil?

      unless @_params[:aliases].nil?
        # aliases must be an array
        return_api_error(
          ApiErrors.[](:invalid_account_aliases)
        ) unless @_params[:aliases].is_a?(Array)
      end

      unless @_params[:sources].nil?
        # sources must be an array
        return_api_error(
          ApiErrors.[](:invalid_account_sources)
        ) unless @_params[:sources].is_a?(Array)
      end

      # check permissions for parameters
      raise Pundit::NotAuthorizedError unless policy(MailAccount).create_with?(
        @_params
      )

      # fetch aliases as an array of MailAlias
      unless @_params[:aliases].nil?
        aliases = MailAlias.all(id: 0)
        mailalias_ids = @_params.delete(:aliases)
        mailalias_ids.each do |alias_id|
          a = MailAlias.get(alias_id)
          # alias must belong to the same domain
          return_api_error(
            ApiErrors.[](:invalid_alias_for_account)
          ) unless a.domain_id == @_params[:domain_id]
          aliases.push(a)
        end
        @_params[:mail_aliases] = aliases
      end

      # fetch sources as an array of MailSource
      unless @_params[:sources].nil?
        sources = MailSource.all(id: 0)
        mailsource_ids = @_params.delete(:sources)
        mailsource_ids.each do |source_id|
          s = MailSource.get(source_id)
          # source must belong to the same domain
          return_api_error(
            ApiErrors.[](:invalid_source_for_account)
          ) unless s.domain_id == @_params[:domain_id]
          sources.push(s)
        end
        @_params[:mail_sources] = sources
      end

      # perform validations
      @mailaccount = MailAccount.new(@_params)
      unless @mailaccount.valid?
        errors = extract_object_errors(object: @mailaccount)
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
        email: @_params[:email],
        domain_id: @_params[:domain_id]
      )

      if @mailaccount.save
        log_user('info', "created MailAccount #{@mailaccount.as_json}")
        @result = ApiResponseSuccess.new(status_code: 201,
                                         data: { object: @mailaccount })
        loc = "#{request.base_url}/api/v1/mailaccounts/#{@mailaccount.id}"
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
    @mailaccount = MailAccount.get(params[:id])
    return_api_error(ApiErrors.[](:not_found)) if @mailaccount.nil?
  end

  namespace '/:id' do
    delete do
      @result = nil

      # check creation permissions. i.e. admin/quotacheck
      authorize(@mailaccount, :destroy?)

      begin
        # check for show errors request
        show_errors = params.key?('verbose')

        # prevent any action being performed on a detroyed resource
        return_api_error(ApiErrors.[](:not_found)) if @mailaccount.destroyed?

        @result = if @mailaccount.destroy
                    log_user('info',
                             "deleted MailAccount #{@mailaccount.as_json}")
                    ApiResponseSuccess.new
                  elsif show_errors
                    errors = extract_destroy_errors(object: @mailaccount)
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
      authorize(@mailaccount, :update?)

      begin
        # check for show errors request
        show_validation_errors = params.key?('validate')
        show_errors = params.key?('verbose')

        # prevent any action being performed on a detroyed resource
        return_api_error(ApiErrors.[](:not_found)) if @mailaccount.destroyed?

        # get json data from request body and symbolize all keys
        request.body.rewind
        @_params = JSON.parse(request.body.read)
        @_params = symbolize_params_hash(@_params)

        # force lowercase on email addr
        @_params[:email].downcase! unless @_params[:email].nil?

        # generate dovecot password hash from plaintex
        @_params[:password] = gen_doveadm_pwhash(
          @_params[:password].to_s
        ) unless @_params[:password].nil?

        # remove unmodified values from input params
        @_params.each_key do |key|
          next unless @mailaccount.model.properties.map(&:name).include?(key)
          @_params.delete(key) if @_params[key] == @mailaccount.send(key)
        end

        unless @_params[:aliases].nil?
          # aliases must be an array
          return_api_error(
            ApiErrors.[](:invalid_account_aliases)
          ) unless @_params[:aliases].is_a?(Array)
        end

        unless @_params[:sources].nil?
          # sources must be an array
          return_api_error(
            ApiErrors.[](:invalid_account_sources)
          ) unless @_params[:sources].is_a?(Array)
        end

        # check permissions for parameters
        raise Pundit::NotAuthorizedError unless policy(
          @mailaccount
        ).update_with?(
          @_params
        )

        # fetch aliases as an array of MailAlias
        unless @_params[:aliases].nil?
          aliases = MailAlias.all(id: 0)
          mailalias_ids = @_params.delete(:aliases)
          mailalias_ids.each do |alias_id|
            a = MailAlias.get(alias_id)
            # alias must belong to the same domain
            return_api_error(
              ApiErrors.[](:invalid_alias_for_account)
            ) unless a.domain_id == @_params[:domain_id]
            aliases.push(a)
          end
          @_params[:mail_aliases] = aliases
        end

        # fetch sources as an array of MailSource
        unless @_params[:sources].nil?
          sources = MailSource.all(id: 0)
          mailsource_ids = @_params.delete(:sources)
          mailsource_ids.each do |source_id|
            s = MailSource.get(source_id)
            # source must belong to the same domain
            return_api_error(
              ApiErrors.[](:invalid_source_for_account)
            ) unless s.domain_id == @_params[:domain_id]
            sources.push(s)
          end
          @_params[:mail_sources] = sources
        end

        # perform validations on a dummy object, check only supplied attributes
        dummy = MailAccount.new(@_params)
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

        unless @_params[:email].nil?
          # force lowercase on email addr
          @_params[:email].downcase!

          # perform sanity checks
          if @_params.key?(:domain_id)
            if @_params[:email] == @mailaccount.email
              check_domain_for_email_address(
                domain_id: @_params[:domain_id],
                email: @_params[:email]
              )
            end
            if @_params[:domain_id] == @mailaccount.domain_id
              check_email_address_for_domain(
                email: @_params[:email],
                domain_id: @_params[:domain_id]
              )
            end
          end
        end

        # remember old values for log message
        old_attributes = @mailaccount.as_json

        @result = if @mailaccount.update(@_params)
                    log_user(
                      'info',
                      "updated MailAccount #{old_attributes} with #{@_params}"
                    )
                    ApiResponseSuccess.new(data: { object: @mailaccount })
                  else
                    errors = extract_object_errors(object: @mailaccount)
                    log_user('debug', "validation_errors: #{errors}")
                    if show_validation_errors || show_errors
                      return_api_error(ApiErrors.[](:failed_update),
                                       errors: { validation: errors })
                    else
                      return_api_error(ApiErrors.[](:failed_update))
                    end
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
      return_authorized_resource(object: @mailaccount) if authorize(
        @mailaccount,
        :show?
      )
    end

    # sieve script upload / download
    get '/sievescript' do
      file = sieve_filename
      content_type 'application/octet-stream'
      send_file(file,
                disposition: 'attachment'.dup,
                filename: File.basename(file))
    end

    post '/sievescript' do
      input_file = params[:data][:tempfile]
      type = params[:data][:type]

      f_type = request.env['HTTP_CONTENT_TYPE'] ||= type
      f_length = request.env['HTTP_CONTENT_LENGTH'] ||= input_file.length

      # global limit for sieve filesize
      return_api_error(
        ApiErrors.[](:sieve_script_size)
      ) if f_length > settings.sieve_max_size

      # curl uploads seem to be always of type application/octet-stream?
      return_api_error(
        ApiErrors.[](:sieve_script_type)
      ) unless %w(application/octet-stream text/plain).include?(f_type)

      begin
        file = Tempfile.new('vhost-api_svscript')
        file.write(input_file.read)

        # filesize quota check
        return_api_error(
          ApiErrors.[](:sieve_script_size_quota)
        ) if file.size.to_i > @mailaccount.quota_sieve_script

        # compile + parse svbin
        svbin = compile_sieve_script(file.path) if check_sieve_script(file.path)
        sieve_actions = count_sieve_actions(svbin)
        sieve_redirects = count_sieve_redirects(svbin)

        # check quota settings
        return_api_error(
          ApiErrors.[](:sieve_actions_quota)
        ) if sieve_actions > @mailaccount.quota_sieve_actions

        return_api_error(
          ApiErrors.[](:sieve_redirects_quota)
        ) if sieve_redirects > @mailaccount.quota_sieve_redirects

        # write to target destination
        File.open(sieve_filename, 'w') do |f|
          file.rewind
          f.write(file.read)
        end

        # cleanup tempfile
        file.unlink
        file.close!

        return_apiresponse(ApiResponseSuccess.new)
      rescue => err
        # cleanup tempfile
        file.unlink
        file.close!
        # unhandled error, always log backtrace
        log_user('error', err.message)
        log_user('error', err.backtrace.join("\n"))
        # print backtrace in api response only if we're in development env
        errors = if settings.environment == :development
                   { errors: [err.message, err.backtrace] }
                 else
                   { errors: err.message }
                 end
        return_apiresponse(api_error(ApiErrors.[](:internal_error), errors))
      end
    end
  end
end
