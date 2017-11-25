# frozen_string_literal: true

error AuthenticationError do
  headers['WWW-Authenticate'] = 'Basic realm="Vhost-API"'
  return_api_error(ApiErrors.[](:authentication_failed))
end

error Pundit::NotAuthorizedError do
  return_api_error(ApiErrors.[](:unauthorized))
end

error DataObjects::ConnectionError do
  return_api_error(ApiErrors.[](:db_connection_failed))
end

not_found do
  return_api_error(ApiErrors.[](:not_found))
end
