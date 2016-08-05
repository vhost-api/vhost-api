# frozen_string_literal: true
require File.expand_path '../../spec_helper.rb', __FILE__

describe 'VHost-API Application' do
  let(:appconfig) { YAML.load(File.read('config/appconfig.yml'))['test'] }

  context 'by an unauthenticated user' do
    it 'returns an an API unauthorized error' do
      get '/'
      expect(last_response.status).to eq(403)
      expect(last_response.body).to eq(
        return_json_pretty(
          api_error(ApiErrors.[](:unauthorized)).to_json
        )
      )
    end
  end

  it 'returns an API Error for unexisting routes/endpoints' do
    clear_cookies

    testuser = create(:admin)

    get(
      '/herp/derp/fooobar',
      nil,
      appconfig[:session][:key] => {
        user_id: testuser.id,
        group: Group.get(testuser.group_id).name
      }
    )

    expect(last_response.status).to eq(404)
    expect(last_response.body).to eq(
      return_json_pretty(
        api_error(ApiErrors.[](:not_found)).to_json
      )
    )
  end
end
