# frozen_string_literal: true
module AuthHelpers
  def auth_login_params(login, password)
    { 'user' => login, 'password' => password, 'apikey' => 'rspec' }
  end

  def auth_headers_basic(login, password)
    method = 'Basic'
    credentials = "#{login}:#{password}"
    auth_secret = Base64.encode64(credentials).delete("\n")

    { 'HTTP_AUTHORIZATION' => "#{method} #{auth_secret}" }
  end

  def auth_headers_apikey(user_id)
    method = 'VHOSTAPI-KEY'
    credentials = "#{user_id}:#{fetch_apikey(user_id)}"
    auth_secret = Base64.encode64(credentials).delete("\n")

    { 'HTTP_AUTHORIZATION' => "#{method} #{auth_secret}" }
  end

  def fetch_apikey(user_id)
    apikey = Apikey.first_or_new(user_id: user_id, comment: 'rspec')
    key = SecureRandom.hex(32)
    apikey.enabled = true
    apikey.apikey = Digest::SHA512.hexdigest(key)
    apikey.save

    key
  end
end
