# frozen_string_literal: true
require File.expand_path '../spec_helper.rb', __FILE__

describe 'VHost-API Application' do
  it 'redirects unauthenticated users to login page' do
    get '/'
    expect(last_response.redirect?).to be_truthy
    follow_redirect!
    expect(last_request.path).to eq('/login')
  end
end
