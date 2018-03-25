# frozen_string_literal: true

require File.expand_path('../spec_helper.rb', __dir__)

# rubocop:disable Metrics/BlockLength
describe 'VHost-API Application' do
  # rubocop:disable Security/YAMLLoad
  let(:appconfig) { YAML.load(File.read('config/appconfig.yml'))['test'] }

  # rubocop:enable Security/YAMLLoad

  context 'with an unauthenticated user' do
    # rubocop:disable RSpec/MultipleExpectations
    it 'returns APP and API versions' do
      get '/'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq(
        spec_json_pretty(
          {
            app_version: '0.1.3-alpha',
            api_version: 'v1'
          }.to_json
        )
      )
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  # rubocop:disable RSpec/MultipleExpectations
  it 'returns an API Error for unexisting routes/endpoints' do
    password = 'secret'
    testuser = create(:admin, password: password)

    credentials = "#{testuser.login}:#{password}"
    auth_secret = Base64.encode64(credentials).strip

    auth_hash = { 'HTTP_AUTHORIZATION' => "Basic #{auth_secret}" }

    get '/herp/derp/fooobar', nil, auth_hash

    expect(last_response.status).to eq(404)
    expect(last_response.body).to eq(
      spec_json_pretty(
        api_error(ApiErrors.[](:not_found)).to_json
      )
    )
  end
  # rubocop:enable RSpec/MultipleExpectations
end
# rubocop:enable Metrics/BlockLength
