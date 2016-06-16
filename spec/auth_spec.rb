require File.expand_path '../spec_helper.rb', __FILE__

describe 'VHost-API Authentication' do
  it 'allows accessing the login page' do
    get '/login'
    expect(last_response).to be_ok
    expect(last_response.body).to include('Username')
  end

  it 'redirects unauthenticated users to login page' do
    get '/domains'
    expect(last_response.redirect?).to be_truthy
    follow_redirect!
    expect(last_request.path).to eq('/login')
  end

  it 'allows logging in with valid credentials' do
    clear_cookies
    # p test_session.inspect
    post '/api/v1/auth/login', 'user' => { 'login' => 'max',
                                           'password' => 'muster' }
    expect(last_response.redirect?).to be_truthy
    follow_redirect!
    expect(last_request.path).to eq('/')
  end
end
