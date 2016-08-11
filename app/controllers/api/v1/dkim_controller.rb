# frozen_string_literal: true
namespace '/api/v1/dkims' do
  get do
    @dkims = policy_scope(Dkim)
    return_authorized_collection(object: @dkims, params: params)
  end

  post do
    @result = nil

    # check creation permissions. i.e. admin/quotacheck
    authorize(Dkim, :create?)

    begin
      # get json data from request body and symbolize all keys
      request.body.rewind
      @_params = JSON.parse(request.body.read)
      @_params = symbolize_params_hash(@_params)

      # selector must not be nil
      return_api_error(
        ApiErrors.[](:invalid_dkim_selector)
      ) if @_params[:selector].nil?

      # domain_id must not be nil
      return_api_error(
        ApiErrors.[](:invalid_dkim_domain_id)
      ) if @_params[:domain_id].nil?

      # force lowercase on selector
      @_params[:selector].downcase!

      # check permissions for parameters
      raise Pundit::NotAuthorizedError unless policy(Dkim).create_with?(
        @_params
      )

      # require both or none of the keys (XOR)
      if @_params[:private_key].nil? ^ @_params[:public_key].nil?
        return_api_error(ApiErrors.[](:invalid_dkim_keypair))
      end

      # generate new keypar if nothing provided in request
      if @_params[:private_key].nil? && @_params[:public_key].nil?
        keypair = SSHKey.generate(
          type: 'RSA',
          bits: 4096,
          comment: nil,
          passphrase: nil
        )

        @_params[:private_key] = keypair.private_key
        @_params[:public_key] = keypair.public_key
      end

      @dkim = Dkim.new(@_params)
      if @dkim.save
        @result = ApiResponseSuccess.new(status_code: 201,
                                         data: { object: @dkim })
        loc = [request.base_url, 'api', 'v1', 'dkims', @dkim.id].join('/')
        response.headers['Location'] = loc
      end
    rescue ArgumentError
      @result = api_error(ApiErrors.[](:invalid_request))
    rescue JSON::ParserError
      @result = api_error(ApiErrors.[](:malformed_request))
    rescue DataMapper::SaveFailureError
      @result = api_error(ApiErrors.[](:failed_create))
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

      # prevent any action being performed on a detroyed resource
      return_api_error(ApiErrors.[](:failed_delete)) if @dkim.destroyed?

      # check creation permissions. i.e. admin/quotacheck
      authorize(@dkim, :destroy?)

      begin
        @result = if @dkim.destroy
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
      authorize(@dkim, :update?)

      begin
        # get json data from request body and symbolize all keys
        request.body.rewind
        @_params = JSON.parse(request.body.read)
        @_params = symbolize_params_hash(@_params)

        # prevent any action being performed on a detroyed resource
        return_api_error(ApiErrors.[](:failed_update)) if @dkim.destroyed?

        [:selector, :domain_id, :private_key, :public_key].each do |key|
          next unless @_params.key?(key)
          # key must not be nil
          return_api_error(
            ApiErrors.[]("invalid_dkim_#{key}".to_sym)
          ) if @_params[key].nil?
        end

        # force lowercase on selector
        @_params[:selector].downcase! if @_params.key?(:selector)

        # check permissions for parameters
        raise Pundit::NotAuthorizedError unless policy(
          @dkim
        ).update_with?(
          @_params
        )

        @result = if @dkim.update(@_params)
                    ApiResponseSuccess.new(data: { object: @dkim })
                  else
                    api_error(ApiErrors.[](:failed_update))
                  end
      rescue ArgumentError
        @result = api_error(ApiErrors.[](:invalid_request))
      rescue JSON::ParserError
        @result = api_error(ApiErrors.[](:malformed_request))
      rescue DataMapper::SaveFailureError
        @result = api_error(ApiErrors.[](:failed_update))
      end
      return_apiresponse @result
    end

    get do
      return_authorized_resource(object: @dkim) if authorize(
        @dkim,
        :show?
      )
    end
  end
end
