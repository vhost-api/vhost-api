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
      # get json data from request body and symbolize all keys
      request.body.rewind
      @_params = JSON.parse(request.body.read)
      @_params = symbolize_params_hash(@_params)

      # author must not be nil
      return_api_error(
        ApiErrors.[](:invalid_dkimsigning_author)
      ) if @_params[:author].nil?

      # dkim_id must not be nil
      return_api_error(
        ApiErrors.[](:invalid_dkimsigning_dkim_id)
      ) if @_params[:dkim_id].nil?

      # force lowercase on author
      @_params[:author].downcase!

      # perform sanity checks
      check_dkim_author_for_dkim(
        author: @_params[:author],
        dkim_id: @_params[:dkim_id]
      )

      # check permissions for parameters
      raise Pundit::NotAuthorizedError unless policy(DkimSigning).create_with?(
        @_params
      )

      @dkimsigning = DkimSigning.new(@_params)
      if @dkimsigning.save
        @result = ApiResponseSuccess.new(status_code: 201,
                                         data: { object: @dkimsigning })
        loc = "#{request.base_url}/api/v1/dkimsignings/#{@dkimsigning.id}"
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
    @dkimsigning = DkimSigning.get(params[:id])
    return_api_error(ApiErrors.[](:not_found)) if @dkimsigning.nil?
  end

  namespace '/:id' do
    delete do
      @result = nil

      # prevent any action being performed on a detroyed resource
      return_api_error(ApiErrors.[](:failed_delete)) if @dkimsigning.destroyed?

      # check creation permissions. i.e. admin/quotacheck
      authorize(@dkimsigning, :destroy?)

      begin
        @result = if @dkimsigning.destroy
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
      authorize(@dkimsigning, :update?)

      begin
        # get json data from request body and symbolize all keys
        request.body.rewind
        @_params = JSON.parse(request.body.read)
        @_params = symbolize_params_hash(@_params)

        # prevent any action being performed on a detroyed resource
        return_api_error(
          ApiErrors.[](:failed_update)
        ) if @dkimsigning.destroyed?

        if @_params.key?(:author)
          # author must not be nil if provided
          return_api_error(
            ApiErrors.[](:invalid_dkimsigning_author)
          ) if @_params[:author].nil?

          # force lowercase on author
          @_params[:author].downcase!

          # perform sanity checks
          check_dkim_author_for_dkim(
            author: @_params[:author],
            dkim_id: @dkimsigning.dkim_id
          )
        end

        # check permissions for parameters
        raise Pundit::NotAuthorizedError unless policy(
          @dkimsigning
        ).update_with?(
          @_params
        )

        @result = if @dkimsigning.update(@_params)
                    ApiResponseSuccess.new(data: { object: @dkimsigning })
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
      return_authorized_resource(object: @dkimsigning) if authorize(
        @dkimsigning,
        :show?
      )
    end
  end
end
