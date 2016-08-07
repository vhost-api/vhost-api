# frozen_string_literal: true
namespace '/api/v1/auth' do
  post '/login' do
    p params
    return_api_error(
      ApiErrors.[](:invalid_request)
    ) unless params['user'] && params['password'] && params['apikey']

    user = User.first(login: params['user'])

    raise AuthenticationError if user.nil? || !user.enabled?

    raise AuthenticationError unless user.authenticate(params['password'])

    # fetch desired apikey
    apikey = user.apikeys.first_or_new(comment: params['apikey'])

    # if we have initialized a new apikey, generate random key and save it
    if apikey.dirty?
      apikey.apikey = SecureRandom.hex(32)
      apikey.enabled = true
      apikey.save
    end

    status 200
    return_json_pretty({ apikey: apikey.apikey }.to_json)
  end
end
