# frozen_string_literal: true
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

def parse_base64_secret(value)
  Base64.decode64(value).strip.split(':')
end

def authenticate_password(value)
  credentials = parse_base64_secret(value)
  login = credentials.shift
  password = credentials.shift

  user = User.first(login: login)
  raise AuthenticationError if user.nil? || !user.enabled?
  return user if user.authenticate(password)
  raise AuthenticationError
end

def authenticate_apikey(value)
  credentials = parse_base64_secret(value)
  user_id = credentials.shift.to_i
  apikey = credentials.shift

  user = User.get(user_id)
  raise AuthenticationError if user.nil? || !user.enabled?
  return user if user.apikeys.map(&:apikey).include?(apikey)
  raise AuthenticationError
end
