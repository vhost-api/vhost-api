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
      # get json data from request body and symbolize all keys
      request.body.rewind
      @_params = JSON.parse(request.body.read)
      @_params = symbolize_params_hash(@_params)

      # email addr must not be nil
      return_api_error(ApiErrors.[](:invalid_email)) if @_params[:email].nil?

      # password must not be nil
      return_api_error(
        ApiErrors.[](:password_required)
      ) if @_params[:password].nil?

      # generate dovecot password hash from plaintex
      @_params[:password] = gen_doveadm_pwhash(@_params[:password].to_s)

      # force lowercase on email addr
      @_params[:email].downcase!

      # check permissions for parameters
      raise Pundit::NotAuthorizedError unless policy(MailAccount).create_with?(
        @_params
      )

      # perform sanity checks
      check_email_address_for_domain(
        email: @_params[:email],
        domain_id: @_params[:domain_id]
      )

      @mailaccount = MailAccount.new(@_params)
      if @mailaccount.save
        @result = ApiResponseSuccess.new(status_code: 201,
                                         data: { object: @mailaccount })
        loc = "#{request.base_url}/api/v1/mailaccounts/#{@mailaccount.id}"
        response.headers['Location'] = loc
      end
    rescue ArgumentError
      @result = api_error(ApiErrors.[](:invalid_request))
    rescue JSON::ParserError
      @result = api_error(ApiErrors.[](:malformed_request))
    rescue DataMapper::SaveFailureError
      @result = if MailAccount.first(email: @_params[:email]).nil?
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
    @mailaccount = MailAccount.get(params[:id])
    return_api_error(ApiErrors.[](:not_found)) if @mailaccount.nil?
  end

  namespace '/:id' do
    delete do
      @result = nil

      # prevent any action being performed on a detroyed resource
      return_api_error(ApiErrors.[](:failed_delete)) if @mailaccount.destroyed?

      # check creation permissions. i.e. admin/quotacheck
      authorize(@mailaccount, :destroy?)

      begin
        @result = if @mailaccount.destroy
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
      authorize(@mailaccount, :update?)

      begin
        # get json data from request body and symbolize all keys
        request.body.rewind
        @_params = JSON.parse(request.body.read)
        @_params = symbolize_params_hash(@_params)

        # prevent any action being performed on a detroyed resource
        return_api_error(
          ApiErrors.[](:failed_update)
        ) if @mailaccount.destroyed?

        # generate dovecot password hash from plaintex
        unless @_params[:password].nil?
          @_params[:password] = gen_doveadm_pwhash(@_params[:password].to_s)
        end

        if @_params.key?(:email)
          # email addr must not be nil
          return_api_error(
            ApiErrors.[](:invalid_email)
          ) if @_params[:email].nil?

          # force lowercase on email addr
          @_params[:email].downcase!

          # perform sanity checks
          if @_params.key?(:domain_id)
            if @_params[:email] == @mailaccount.email
              check_domain_for_email_address(
                domain_id: @_params[:domain_id],
                email: @_params[:email]
              )
            else
              check_email_address_for_domain(
                email: @_params[:email],
                domain_id: @_params[:domain_id]
              )
            end
          end
        end

        # check permissions for parameters
        raise Pundit::NotAuthorizedError unless policy(
          @mailaccount
        ).update_with?(
          @_params
        )

        @result = if @mailaccount.update(@_params)
                    ApiResponseSuccess.new(data: { object: @mailaccount })
                  else
                    api_error(ApiErrors.[](:failed_update))
                  end
      rescue ArgumentError
        @result = api_error(ApiErrors.[](:invalid_request))
      rescue JSON::ParserError
        @result = api_error(ApiErrors.[](:malformed_request))
      rescue DataMapper::SaveFailureError
        @result = if MailAccount.first(email: @_params[:email]).nil?
                    api_error(ApiErrors.[](:failed_update))
                  else
                    api_error(ApiErrors.[](:resource_conflict))
                  end
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
      ensure
        # cleanup tempfile
        file.unlink
        file.close!
      end
    end
  end
end
