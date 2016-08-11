# frozen_string_literal: true
require File.expand_path '../../spec_helper.rb', __FILE__

describe 'VHost-API URL Query' do
  let(:appconfig) { YAML.load(File.read('config/appconfig.yml'))['test'] }

  api_versions = %w(1)

  api_versions.each do |api_version|
    context "API version #{api_version}" do
      let!(:testadmin) { create(:admin, password: 'secret') }

      let!(:testdomain1) do
        create(:domain, name: 'example.test.com', enabled: false)
      end

      let!(:testdomain2) do
        create(:domain, name: 'www.test.com', enabled: true)
      end

      let!(:testdomain3) do
        create(:domain, name: 'example.test2.com', enabled: false)
      end

      let!(:testdomain4) do
        create(:domain, name: 'www.test2.com', enabled: true)
      end

      context 'Searching' do
        it 'Search for strings' do
          get("/api/v#{api_version}/domains?q[name]=example.", nil,
              auth_headers_apikey(testadmin.id))

          collection = {
            testdomain1.id => testdomain1,
            testdomain3.id => testdomain3
          }

          result = spec_json_pretty(collection.to_json)

          expect(last_response.body).to eq(result)
        end

        it 'Search for booleans' do
          get("/api/v#{api_version}/domains?q[enabled]=true", nil,
              auth_headers_apikey(testadmin.id))

          collection = {
            testdomain2.id => testdomain2,
            testdomain4.id => testdomain4
          }

          result = spec_json_pretty(collection.to_json)

          expect(last_response.body).to eq(result)
        end

        it 'Search for non-existing field' do
          get("/api/v#{api_version}/domains?q[non_existing_field]=true", nil,
              auth_headers_apikey(testadmin.id))

          expect(last_response.status).to eq(400)
          expect(last_response.body).to eq(
            spec_json_pretty(
              api_error(ApiErrors.[](:invalid_query)).to_json
            )
          )
        end
      end

      context 'Filtering' do
        it 'limits the return objects' do
          get("/api/v#{api_version}/domains?limit=3", nil,
              auth_headers_apikey(testadmin.id))

          collection = {
            testdomain1.id => testdomain1,
            testdomain2.id => testdomain2,
            testdomain3.id => testdomain3
          }

          result = spec_json_pretty(collection.to_json)

          expect(last_response.body).to eq(result)
        end

        it 'Offset the first two objects and get two objects' do
          get("/api/v#{api_version}/domains?limit=2&offset=2", nil,
              auth_headers_apikey(testadmin.id))

          collection = {
            testdomain3.id => testdomain3,
            testdomain4.id => testdomain4
          }

          result = spec_json_pretty(collection.to_json)

          expect(last_response.body).to eq(result)
        end
      end

      context 'Sorting' do
        it 'Sort by name ascending' do
          get("/api/v#{api_version}/domains?sort=name", nil,
              auth_headers_apikey(testadmin.id))

          collection = {
            testdomain1.id => testdomain1,
            testdomain3.id => testdomain3,
            testdomain2.id => testdomain2,
            testdomain4.id => testdomain4
          }

          result = spec_json_pretty(collection.to_json)

          expect(last_response.body).to eq(result)
        end

        it 'Sort by id descending' do
          get("/api/v#{api_version}/domains?sort=-id", nil,
              auth_headers_apikey(testadmin.id))

          collection = {
            testdomain4.id => testdomain4,
            testdomain3.id => testdomain3,
            testdomain2.id => testdomain2,
            testdomain1.id => testdomain1
          }

          result = spec_json_pretty(collection.to_json)

          expect(last_response.body).to eq(result)
        end
      end

      context 'Fields' do
        it 'Only get name and id field' do
          get("/api/v#{api_version}/domains?fields=id,name", nil,
              auth_headers_apikey(testadmin.id))

          collection = {
            testdomain1.id => testdomain1,
            testdomain2.id => testdomain2,
            testdomain3.id => testdomain3,
            testdomain4.id => testdomain4
          }

          result = {}

          collection.values.each do |record|
            result[record.id] = {
              'id' => record.id,
              'name' => record.name
            }
          end

          result = spec_json_pretty(result.to_json)

          expect(last_response.body).to eq(result)
        end

        it 'Get non-existing field' do
          get("/api/v#{api_version}/domains?fields=id,non_existing_field", nil,
              auth_headers_apikey(testadmin.id))

          expect(last_response.status).to eq(400)
          expect(last_response.body).to eq(
            spec_json_pretty(
              api_error(ApiErrors.[](:invalid_query)).to_json
            )
          )
        end
      end
    end
  end
end
