# frozen_string_literal: true

require File.expand_path('../spec_helper.rb', __dir__)

# rubocop:disable Metrics/BlockLength
describe 'VHost-API Authentication' do
  # rubocop:disable Security/YAMLLoad
  let(:appconfig) { YAML.load(File.read('config/appconfig.yml'))['test'] }

  # rubocop:enable Security/YAMLLoad

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

    # rubocop:disable RSpec/MultipleExpectations
    it 'returns an apikey' do
      post '/api/v1/auth/login', auth_login_params(testuser.login, password)

      expect(JSON.parse(last_response.body)['apikey'].length).to eq(64)

      expect(
        Digest::SHA512.hexdigest(JSON.parse(last_response.body)['apikey'])
      ).to eq(
        Apikey.first(user_id: testuser.id, comment: 'rspec').apikey
      )
    end
    # rubocop:enable RSpec/MultipleExpectations

    it 'returns an API error if apikey quota exhausted' do
      params = auth_login_params(testuser.login, password)
      quota_apikeys = testuser.packages.map(&:quota_apikeys).reduce(0, :+)
      # exhaust the quota
      quota_apikeys.times do |i|
        params['apikey_comment'] = "test#{i}"
        post '/api/v1/auth/login', params
      end

      # try to allocate another apikey
      params['apikey_comment'] = 'rspec'

      post '/api/v1/auth/login', params

      expect(last_response.body).to eq(
        spec_json_pretty(
          api_error(ApiErrors.[](:quota_apikey)).to_json
        )
      )
    end
  end

  context 'with invalid credentials' do
    it 'does not allow login' do
      post '/api/v1/auth/login',
           'user' => testuser.login,
           'password' => 'wrong_password',
           'apikey_comment' => 'rspec'

      expect(last_response.body).to eq(
        spec_json_pretty(
          api_error(ApiErrors.[](:authentication_failed)).to_json
        )
      )
    end
  end
end
# rubocop:enable Metrics/BlockLength
