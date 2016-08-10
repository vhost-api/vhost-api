# frozen_string_literal: true
require File.expand_path '../../spec_helper.rb', __FILE__

describe 'VHost-API URL Query' do
  let(:appconfig) { YAML.load(File.read('config/appconfig.yml'))['test'] }

  api_versions = %w(1)

  api_versions.each do |api_version|
    context "API version #{api_version}" do
      let!(:testadmin) { create(:admin, password: 'secret') }
      let!(:testdomain1) { create(:domain, name: 'example.test.com', enabled: false) }
      let!(:testdomain2) { create(:domain, name: 'www.test.com', enabled: true) }
      let!(:testdomain3) { create(:domain, name: 'example.test2.com', enabled: false) }
      let!(:testdomain4) { create(:domain, name: 'www.test2.com', enabled: true) }

      context 'Searching' do
        it 'Search for strings' do
          get("/api/v#{api_version}/domains?q[name]=example.", nil,
              auth_headers_apikey(testadmin.id)
             )

          collection = {
            testdomain1.id => testdomain1,
            testdomain3.id => testdomain3,
          }          

          result = spec_json_pretty(collection.to_json)

          expect(last_response.body).to eq(result)
        end

        it 'Search for booleans' do
          get("/api/v#{api_version}/domains?q[enabled]=true", nil,
              auth_headers_apikey(testadmin.id)
             )

          collection = {
            testdomain2.id => testdomain2,
            testdomain4.id => testdomain4,
          }          

          result = spec_json_pretty(collection.to_json)

          expect(last_response.body).to eq(result)          
        end
      end

      context 'Filtering' do
        it 'limits the return objects' do
          get("/api/v#{api_version}/domains?limit=3", nil,
              auth_headers_apikey(testadmin.id)
             )

          collection = {
            testdomain1.id => testdomain1,
            testdomain2.id => testdomain2,
            testdomain3.id => testdomain3,
          }          

          result = spec_json_pretty(collection.to_json)

          expect(last_response.body).to eq(result)
        end

        it 'Offset the first two objects and get two objects' do
          get("/api/v#{api_version}/domains?limit=2&offset=2", nil,
              auth_headers_apikey(testadmin.id)
             )

          collection = {
            testdomain3.id => testdomain3,
            testdomain4.id => testdomain4,            
          }

          result = spec_json_pretty(collection.to_json)

          expect(last_response.body).to eq(result)
        end        
      end

      context 'Sorting' do
        it 'Sort by name ascending' do
          get("/api/v#{api_version}/domains?sort=name", nil,
              auth_headers_apikey(testadmin.id)
             )

          collection = {
            testdomain1.id => testdomain1,
            testdomain3.id => testdomain3,
            testdomain2.id => testdomain2,
            testdomain4.id => testdomain4,
          }

          result = spec_json_pretty(collection.to_json)

          expect(last_response.body).to eq(result)
        end

        it 'Sort by id descending' do
          get("/api/v#{api_version}/domains?sort=-id", nil,
              auth_headers_apikey(testadmin.id)
             )

          collection = {
            testdomain4.id => testdomain4,            
            testdomain3.id => testdomain3,
            testdomain2.id => testdomain2,
            testdomain1.id => testdomain1,
          }

          result = spec_json_pretty(collection.to_json)

          expect(last_response.body).to eq(result)
        end                
      end

      context 'Fields' do
        it 'Only get name and id field' do
          get("/api/v#{api_version}/domains?fields=id,name", nil,
              auth_headers_apikey(testadmin.id)
             )

          collection = {
            testdomain1.id => testdomain1,
            testdomain2.id => testdomain2,
            testdomain3.id => testdomain3,
            testdomain4.id => testdomain4,            
          }

          result = spec_json_pretty(collection.to_json(only: [:id, :name]))

          expect(last_response.body).to eq(result)
        end                
      end
    end
  end
end
