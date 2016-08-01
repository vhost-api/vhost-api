# frozen_string_literal: true
namespace '/api/v1/dkimsignings' do
  helpers do
    def fetch_scoped_dkimsignings
      @dkimsignings = policy_scope(DkimSigning)
    end
  end

  get do
    fetch_scoped_dkimsignings
    return_authorized_collection(object: @dkimsignings)
  end

  post do
    @result = nil

    # check creation permissions. i.e. admin/quotacheck
    authorize(DkimSigning, :create?)

    begin
      # get json data from request body and symbolize all keys
      request.body.rewind
      @_params = JSON.parse(request.body.read)
      @_params = @_params.reduce({}) do |memo, (k, v)|
        memo.tap { |m| m[k.to_sym] = v }
      end

      # author must not be nil
      raise(ArgumentError, 'invalid author') if @_params[:author].nil?

      # dkim_id must not be nil
      raise(ArgumentError, 'invalid dkim id') if @_params[:dkim_id].nil?

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
        response.headers['Location'] = [request.base_url,
                                        'api',
                                        'v1',
                                        'dkimsignings',
                                        @dkimsigning.id].join('/')
      end
    rescue ArgumentError
      # 422 = Unprocessable Entity
      @result = ApiResponseError.new(status_code: 422,
                                     error_id: 'invalid request data',
                                     message: $ERROR_INFO.to_s)
    rescue JSON::ParserError
      # 400 = Bad Request
      @result = ApiResponseError.new(status_code: 400,
                                     error_id: 'malformed request data',
                                     message: $ERROR_INFO.to_s)
    rescue DataMapper::SaveFailureError
      # 500 = Internal Server Error
      @result = ApiResponseError.new(status_code: 500,
                                     error_id: 'could not create',
                                     message: $ERROR_INFO.to_s)
    end
    return_apiresponse @result
  end

  before %r{\A/(?<id>\d+)/?.*} do
    # namespace local before blocks are evaluate before global before blocks
    # thus we need to enforce authentication here
    authenticate! if @user.nil?
    @dkimsigning = DkimSigning.get(params[:id])
    return_apiresponse(
      ApiResponseError.new(status_code: 404,
                           error_id: 'not found',
                           message: 'requested resource does not exist')
    ) if @dkimsigning.nil?
  end

  namespace '/:id' do
    delete do
      @result = nil

      # prevent any action being performed on a detroyed resource
      return_apiresponse(
        ApiResponseError.new(status_code: 500,
                             error_id: 'could not delete',
                             message: $ERROR_INFO.to_s)
      ) if @dkimsigning.destroyed?

      # check creation permissions. i.e. admin/quotacheck
      authorize(@dkimsigning, :destroy?)

      begin
        @result = if @dkimsigning.destroy
                    ApiResponseSuccess.new
                  else
                    # 500 = Internal Server Error
                    ApiResponseError.new(status_code: 500,
                                         error_id: 'could not delete',
                                         message: $ERROR_INFO.to_s)
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
        @_params = @_params.reduce({}) do |memo, (k, v)|
          memo.tap { |m| m[k.to_sym] = v }
        end

        # prevent any action being performed on a detroyed resource
        return_apiresponse(
          ApiResponseError.new(status_code: 500,
                               error_id: 'could not delete',
                               message: $ERROR_INFO.to_s)
        ) if @dkimsigning.destroyed?

        if @_params.key?(:author)
          # author must not be nil
          raise(ArgumentError, 'invalid author') if @_params[:author].nil?

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
                    # 500 = Internal Server Error
                    ApiResponseError.new(status_code: 500,
                                         error_id: 'could not update',
                                         message: $ERROR_INFO.to_s)
                  end
      rescue ArgumentError
        # 422 = Unprocessable Entity
        @result = ApiResponseError.new(status_code: 422,
                                       error_id: 'invalid request data',
                                       message: $ERROR_INFO.to_s)
      rescue JSON::ParserError
        # 400 = Bad Request
        @result = ApiResponseError.new(status_code: 400,
                                       error_id: 'malformed request data',
                                       message: $ERROR_INFO.to_s)
      rescue DataMapper::SaveFailureError
        # 500 = Internal Server Error
        @result = ApiResponseError.new(status_code: 500,
                                       error_id: 'could not update',
                                       message: $ERROR_INFO.to_s)
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
