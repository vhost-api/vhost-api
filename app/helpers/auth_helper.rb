# frozen_string_literal: true

# @return [Boolean]
def user?
  @user != nil
end

# tell pundit how to find the user
current_user do
  user? ? @user : authenticate!
end

# Performs authentication and returns user if successful.
#
# @return [User]
def authenticate!
  auth_header = request.env['HTTP_AUTHORIZATION']
  raise AuthenticationError unless auth_header
  method, value = [nil, '']
  begin
    method, value = auth_header.split(%r{\s+}) || [nil, '']
  rescue => e
    log_app('error', e)
    raise AuthenticationError
  end
  case method
  when 'Basic' then @user = authenticate_password(value)
  when 'VHOSTAPI-KEY' then @user = authenticate_apikey(value)
  else raise AuthenticationError
  end
  raise AuthenticationError if @user.nil?
  @user
end

# Decodes a base64 encoded secret and splits the
# resulting string at the colon separator.
#
# @param value [String]
# @return [Array(String)]
def parse_base64_secret(value)
  Base64.decode64(value).delete("\n").split(':')
end

# Performs authentication based on the HTTP Authorization
# header for Basic method.
#
# @param value [String]
# @return [User]
def authenticate_password(value)
  credentials = parse_base64_secret(value)
  login = credentials.shift
  password = credentials.shift

  user = User.first(login: login)
  raise AuthenticationError if user.nil? || !user.enabled?
  return user if user.authenticate(password)
  raise AuthenticationError
end

# Performs authentication based on the HTTP Authorization
# header for VHOSTAPI-KEY method.
#
# @param value [String]
# @return [User]
def authenticate_apikey(value)
  credentials = parse_base64_secret(value)
  user_id = credentials.shift.to_i
  apikey = credentials.shift

  check_apikey_for_user(user_id, apikey)
end

# Performs validations on user and apikey.
# Both need to map to existing records and need
# to be enabled
#
# @param user_id [Fixnum]
# @param apikey [String]
# @return [User]
def check_apikey_for_user(user_id, req_apikey)
  user = User.get(user_id)
  raise AuthenticationError if user.nil? || !user.enabled?

  h_apikey = Digest::SHA512.hexdigest(req_apikey)
  raise AuthenticationError unless user.apikeys.map(&:apikey).include?(h_apikey)

  apikey = Apikey.first(apikey: h_apikey)
  return user if apikey.enabled?

  raise AuthenticationError
end
