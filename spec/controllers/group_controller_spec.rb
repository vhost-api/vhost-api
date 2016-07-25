# frozen_string_literal: true
require File.expand_path '../../spec_helper.rb', __FILE__

describe 'VHost-API Group Controller' do
  let(:appconfig) { YAML.load(File.read('config/appconfig.yml'))['test'] }

  context 'by an authenticated and authorized user' do
    before(:each) do
      create(:group, name: 'admin')
      create(:group, name: 'reseller')
      create(:group)
    end

    let(:testadmin) { create(:admin) }

    describe 'GET all' do
      it 'authorizes the request by using the policies' do
        clear_cookies

        get(
          '/api/v1/groups.json', {},
          appconfig[:session][:key] => {
            user_id: testadmin.id,
            group: Group.get(testadmin.group_id).name
          }
        )

        expect(last_response.body).to eq(
          return_json_pretty(Pundit.policy_scope(testadmin, Group).to_json)
        )
      end
      it 'populates an array of groups'
      it 'renders the :index view'
    end

    describe 'GET one' do
      it 'authorizes the request by using the policies'
      it 'assigns the requested group to @group'
      it 'renders the :show view'
    end

    describe 'POST' do
      context 'with valid attributes' do
        it 'authorizes the request by using the policies'
        it 'creates a new group'
        it 'returns an API Success containing the new group'
        it 'returns a valid JSON object'
        it 'redirects to the new group'
      end

      context 'with invalid attributes' do
        it 'authorizes the request by using the policies'
        it 'does not create a new group'
        it 'returns an API Error'
        it 'returns a valid JSON object'
        it 're-renders the :new view'
      end
    end

    describe 'PATCH' do
      context 'with valid attributes' do
        it 'authorizes the request by using the policies'
        it 'updates an existing group with new values'
        it 'returns an API Success containing the updated group'
        it 'returns a valid JSON object'
        it 'redirects to the updated group'
      end

      context 'with invalid attributes' do
        it 'authorizes the request by using the policies'
        it 'does not update the group'
        it 'returns an API Error'
        it 'returns a valid JSON object'
        it 're-renders the :edit view'
      end
    end

    describe 'DELETE' do
      it 'authorizes the request by using the policies'
      it 'deletes the requested group'
      it 'returns a valid JSON object'
      it 'redirects to the #index'
    end
  end

  context 'by an authenticated but unauthorized user' do
    describe 'GET all' do
      it 'returns an authorization error'
      it 'returns an API Error'
      it 'returns a valid JSON object'
    end

    describe 'GET one' do
      it 'returns an authorization error'
      it 'returns an API Error'
      it 'returns a valid JSON object'
    end

    describe 'POST' do
      it 'returns an authorization error'
      it 'returns an API Error'
      it 'returns a valid JSON object'
    end

    describe 'PATCH' do
      it 'returns an authorization error'
      it 'returns an API Error'
      it 'returns a valid JSON object'
    end

    describe 'DELETE' do
      it 'returns an authorization error'
      it 'returns an API Error'
      it 'returns a valid JSON object'
    end
  end

  context 'by an unauthenticated (thus unauthorized) user' do
    before(:each) do
      create(:group, name: 'admin')
      create(:group, name: 'reseller')
    end

    let(:testgroup) { create(:group) }

    describe 'GET all' do
      it 'redirects to the login page' do
        get '/api/v1/groups'
        expect(last_response.redirect?).to be_truthy
        follow_redirect!
        expect(last_request.path).to eq('/login')
      end
    end

    describe 'GET one' do
      it 'redirects to the login page' do
        get "/api/v1/groups/#{testgroup.id}"
        expect(last_response.redirect?).to be_truthy
        follow_redirect!
        expect(last_request.path).to eq('/login')
      end
    end

    describe 'POST' do
      it 'redirects to the login page' do
        post '/api/v1/groups',
             'group' => attributes_for(:group)
        expect(last_response.redirect?).to be_truthy
        follow_redirect!
        expect(last_request.path).to eq('/login')
      end
    end

    describe 'PATCH' do
      it 'redirects to the login page' do
        testgroup_foo = create(:group, name: 'foo')
        patch "/api/v1/groups/#{testgroup_foo.id}",
              'group' => attributes_for(:group)
        expect(last_response.redirect?).to be_truthy
        follow_redirect!
        expect(last_request.path).to eq('/login')
      end
    end

    describe 'DELETE' do
      it 'redirects to the login page' do
        delete "/api/v1/groups/#{testgroup.id}"
        expect(last_response.redirect?).to be_truthy
        follow_redirect!
        expect(last_request.path).to eq('/login')
      end
    end
  end
end
