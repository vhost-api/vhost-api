# frozen_string_literal: true
namespace '/api/v1/auth' do
  post '/login' do
    return_api_error(
      ApiErrors.[](:invalid_request)
    ) unless params['user'] && params['password'] && params['apikey_comment']

    @user = User.first(login: params['user'])

    raise AuthenticationError if @user.nil? || !@user.enabled?

    raise AuthenticationError unless @user.authenticate(params['password'])

    begin
      # allow re-generation of existing apikeys
      authorize(Apikey, :create?) unless @user.apikeys.map(&:comment).include?(
        params['apikey_comment']
      )

      # fetch desired apikey
      apikey = @user.apikeys.first_or_new(comment: params['apikey_comment'])

      # always generate fresh apikey and only store its sha512 hash in the db
      key = SecureRandom.hex(32)
      apikey.apikey = Digest::SHA512.hexdigest(key)
      apikey.enabled = true
      apikey.save

      status 200
      return_json_pretty({ user_id: @user.id, apikey: key }.to_json)
    rescue Pundit::NotAuthorizedError
      # show a more fitting message than the 'permission denied'
      return_api_error(ApiErrors.[](:quota_apikey))
    end
  end
end
