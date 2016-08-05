# frozen_string_literal: true
def authenticate!
  @user = valid_apikey?(request.env) if apikey_headers?(request.env)
  @user = User.get(session[:user_id]) unless session[:user_id].nil?
  raise Pundit::NotAuthorizedError if @user.nil?
  @user
end

def valid_apikey?(env)
  user = User.get(env['HTTP_X_VHOSTAPI_USER'])
  key = env['HTTP_X_VHOSTAPI_KEY']
  return user if user.apikeys.map(&:apikey).include?(key)
  raise Pundit::NotAuthorizedError
end

def apikey_headers?(env)
  env['HTTP_X_VHOSTAPI_USER'] && env['HTTP_X_VHOSTAPI_KEY']
end
