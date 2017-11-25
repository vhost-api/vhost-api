# frozen_string_literal: true

require File.expand_path '../../spec_helper.rb', __FILE__

describe 'VHost-API Compression gzip/deflate' do
  let(:appconfig) { YAML.load(File.read('config/appconfig.yml'))['test'] }

  api_versions = %w[1]

  api_versions.each do |api_version|
    context "API version #{api_version}" do
      let(:admingroup) { create(:group, name: 'admin') }
      let(:resellergroup) { create(:group, name: 'reseller') }
      let(:usergroup) { create(:group, name: 'user') }
      let(:testadmin) { create(:admin, password: 'secret') }
      let(:user1) { create(:user) }
      let(:user2) { create(:user) }
      let(:user3) { create(:user) }
      let(:user4) { create(:user) }

      context 'client supports compression' do
        it 'responds with compressed data' do
          %w[deflate gzip deflate,gzip gzip,deflate].each do |method|
            req_headers = auth_headers_apikey(testadmin.id)
            req_headers['HTTP_ACCEPT_ENCODING'] = method
            get(
              "/api/v#{api_version}/users", nil,
              req_headers
            )
            # response encoding should match client preference
            expect(
              last_response.headers['Content-Encoding']
            ).to eq(method.split(',')[0])
          end
        end
      end

      context 'client does not support compression' do
        it 'responds with uncompressed data' do
          get(
            "/api/v#{api_version}/users", nil,
            auth_headers_apikey(testadmin.id)
          )
          expect(last_response.headers['Content-Encoding']).not_to be
        end
      end
    end
  end
end
