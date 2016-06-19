require File.expand_path '../spec_helper.rb', __FILE__

describe 'VHost-API Authentication' do
  appconfig = YAML.load(File.read('config/appconfig.yml'))[ENV['RACK_ENV']]
  let(:appconfig) { appconfig }

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
    post '/api/v1/auth/login', 'user' => { 'login' => 'max',
                                           'password' => 'muster' }
    expect(last_response.redirect?).to be_truthy
    follow_redirect!
    expect(last_request.path).to eq('/')
  end

  it 'allows logging out from an active session' do
    clear_cookies
    testuser = User.get(3)
    get '/api/v1/auth/logout',
        {},
        appconfig[:session][:key] => { user: testuser,
                                       user_id: testuser.id,
                                       group: Group.get(
                                         testuser.group_id
                                       ).name }
    expect(last_response.redirect?).to be_truthy
    follow_redirect!
    expect(last_request.path).to eq('/')
  end

  it 'shows users name in topnav when logged in' do
    clear_cookies
    testuser = User.get(3)
    get '/',
        {},
        appconfig[:session][:key] => { user: testuser,
                                       user_id: testuser.id,
                                       group: Group.get(
                                         testuser.group_id
                                       ).name }
    expect(last_response).to be_ok
    expect(last_response.body.include?(testuser.name)).to be_truthy
  end
end
