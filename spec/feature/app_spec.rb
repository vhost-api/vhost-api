# frozen_string_literal: true

require File.expand_path '../../spec_helper.rb', __FILE__

describe 'VHost-API Application' do
  let(:appconfig) { YAML.load(File.read('config/appconfig.yml'))['test'] }

  context 'by an unauthenticated user' do
    it 'returns APP and API versions' do
      get '/'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq(
        spec_json_pretty(
          {
            app_version: '0.1.2-alpha',
            api_version: 'v1'
          }.to_json
        )
      )
    end
  end

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
end
