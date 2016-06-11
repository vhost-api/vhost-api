namespace '/api/v1/mailaccounts' do
  helpers do
    def fetch_scoped_mailaccounts
      @mailaccounts = policy_scope(MailAccount)
    end
  end

  get do
    authenticate!
    fetch_scoped_mailaccounts
    # @mailaccounts = MailAccount.all(domain_id: 0)
    # unless @user.nil?
      # if @user.admin?
        # @mailaccounts.concat(MailAccount.all)
      # else
        # @user.domains.each do |domain|
          # @mailaccounts.concat(MailAccount.all(domain_id: domain.id))
        # end
      # end
    # end
    # @mailaccounts = MailAccount.all
    # @mailaccounts.inspect
    return_resource object: @mailaccounts
  end

  post do
    authenticate!

    # 400 = Bad Request
    # halt 400 unless request.body.size > 0

    @result = nil
    begin 
      # get json data from request body
      request.body.rewind
      @params = JSON.parse(request.body.read)

      # generate dovecot password hash from plaintex
      params["password"] = gen_doveadm_pwhash(params["password"].to_s);

      @mailaccount = MailAccount.new(params)
      if @mailaccount.save
        @result = ApiResponseSuccess.new(status_code: 201, data: {object: @mailaccount})
        response.headers['Location'] = "#{request.base_url}/mailaccounts/#{@mailaccount.id}"
      else
        # 500 = Internal Server Error
        @result = ApiResponseError.new(status_code: 500, error_id: "could not create", message: $!.to_s)
      end
    rescue ArgumentError
      # 422 = Unprocessable Entity
      @result = ApiResponseError.new(status_code: 422, error_id: "invalid request data", message: $!.to_s)
    rescue JSON::ParserError
      # 400 = Bad Request
      @result = ApiResponseError.new(status_code: 400, error_id: "malformed request data", message: $!.to_s)
    rescue DataObjects::IntegrityError
      # 409 = Conflict
      @result = ApiResponseError.new(status_code: 409, error_id: "resource conflict", message: $!.to_s)
    rescue DataMapper::SaveFailureError
      # 500 = Internal Server Error
      @result = ApiResponseError.new(status_code: 500, error_id: "could not create", message: $!.to_s)
    end
    return_apiresponse @result
  end

  before %r{\A/(?<id>\d+)/?.*} do
    @mailaccount = MailAccount.get(params[:id])
    # 404 = Not Found
    halt 404 if @mailaccount.nil?
  end

  namespace '/:id' do
    delete do
      @result = nil
      begin
        if @mailaccount.destroy
          @result = ApiResponseSuccess.new(nil)
        else
          # 500 = Internal Server Error
          @result = ApiResponseError.new(status_code: 500, error_id: "could not delete", message: $!.to_s)
        end
      end
      return_apiresponse @result
    end

    patch do
      authenticate!

      authorize @mailaccount, :update?
      # halt 200, "#{request.inspect}"

      @result = nil
      begin
        # get json data from request body
        request.body.rewind()
        @params = JSON.parse(request.body.read)

        # generate dovecot password hash from plaintex
        params["password"] = gen_doveadm_pwhash(params["password"].to_s);

        # halt 400, "#{@params.inspect}"

        if @mailaccount.update(params)
          @result = ApiResponseSuccess.new(data: {object: @mailaccount})
        else
          # 500 = Internal Server Error
          @result = ApiResponseError.new(status_code: 500, error_id: "could not update", message: $!.to_s)
        end
      rescue ArgumentError
        # 422 = Unprocessable Entity
        @result = ApiResponseError.new(status_code: 422, error_id: "invalid request data", message: $!.to_s)
      rescue JSON::ParserError
        # 400 = Bad Request
        @result = ApiResponseError.new(status_code: 400, error_id: "malformed request data", message: $!.to_s)
      rescue DataMapper::SaveFailureError
        # 500 = Internal Server Error
        @result = ApiResponseError.new(status_code: 500, error_id: "could not update", message: $!.to_s)
      end
      return_apiresponse @result
    end

    get do
      authenticate!
      return_resource object: @mailaccount
    end

    get '/edit' do
      authenticate!
      unless @user.admin? or @user.owner_of?(@mailaccount)
        @mailaccount = nil
        flash[:error] = 'Not authorized!'
        session[:return_to] = nil
        redirect '/'
      end
      haml :edit_mailaccount
    end
  end
end
