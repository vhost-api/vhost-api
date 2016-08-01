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

  it 'allows accessing the login page' do
    get '/login'
    expect(last_response).to be_ok
    expect(last_response.body).to include('Username')
  end

  context 'with valid credentials' do
    it 'allows logging in' do
      clear_cookies
      post '/api/v1/auth/login', 'user' => { 'login' => testuser.login,
                                             'password' => password }
      expect(last_response.redirect?).to be_truthy
      follow_redirect!
      expect(last_request.path).to eq('/')
    end
  end

  context 'with invalid credentials' do
    it 'does not allow login and redirects to /login' do
      clear_cookies
      post '/api/v1/auth/login', 'user' => { 'login' => testuser.login,
                                             'password' => 'wrong_password' }
      expect(last_response.redirect?).to be_truthy
      follow_redirect!
      expect(last_request.path).to eq('/login')
    end
  end

  it 'allows logging out from an active session' do
    clear_cookies
    get '/api/v1/auth/logout',
        {},
        appconfig[:session][:key] => { user_id: testuser.id,
                                       group: Group.get(
                                         testuser.group_id
                                       ).name }
    expect(last_response.redirect?).to be_truthy
    follow_redirect!
    expect(last_request.path).to eq('/login')
  end

  it 'shows users name in topnav when logged in' do
    clear_cookies
    get '/',
        {},
        appconfig[:session][:key] => { user_id: testuser.id,
                                       group: Group.get(
                                         testuser.group_id
                                       ).name }
    expect(last_response).to be_ok
    expect(last_response.body.include?(testuser.name)).to be_truthy
  end
end
