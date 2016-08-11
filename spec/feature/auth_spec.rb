# frozen_string_literal: true
require File.expand_path '../../spec_helper.rb', __FILE__

describe 'VHost-API Authentication' do
  let(:appconfig) { YAML.load(File.read('config/appconfig.yml'))['test'] }

  let(:password) { 'muster' }
  let(:testuser) do
    create(:user,
           name: 'Max Mustermann',
           login: 'max',
           password: password)
  end

  context 'with valid credentials' do
    it 'allows accessing the homepage with valid apikey' do
      get '/', nil, auth_headers_apikey(testuser.id)
      expect(last_response.status).to eq(200)
    end

    it 'allows logging in' do
      post '/api/v1/auth/login', auth_login_params(testuser.login, password)
      expect(last_response.status).to eq(200)
    end

    it 'returns valid JSON' do
      post '/api/v1/auth/login', auth_login_params(testuser.login, password)
      expect { JSON.parse(last_response.body) }.not_to raise_exception
    end

    it 'returns an apikey' do
      post '/api/v1/auth/login', auth_login_params(testuser.login, password)

      expect(JSON.parse(last_response.body)['apikey'].length).to eq(64)

      expect(
        Digest::SHA512.hexdigest(JSON.parse(last_response.body)['apikey'])
      ).to eq(
        Apikey.first(user_id: testuser.id, comment: 'rspec').apikey
      )
    end
  end

  context 'with invalid credentials' do
    it 'does not allow login' do
      post '/api/v1/auth/login',
           'user' => testuser.login,
           'password' => 'wrong_password',
           'apikey' => 'rspec'

      expect(last_response.body).to eq(
        spec_json_pretty(
          api_error(ApiErrors.[](:authentication_failed)).to_json
        )
      )
    end
  end
end
