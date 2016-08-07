# frozen_string_literal: true

# Performs authentication and returns user if successful.
#
# @return [User]
def authenticate!
  auth_header = request.env['HTTP_AUTHORIZATION']
  method, value = auth_header.try(:split, %r{\s+}) || [nil, '']
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
  Base64.decode64(value).strip.split(':')
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
  apikey = Apikey.first(apikey: req_apikey)
  raise AuthenticationError if user.nil? || !user.enabled? ||
                               apikey.nil? || !apikey.enabled?
  return user if user.apikeys.include?(apikey)
  raise AuthenticationError
end
