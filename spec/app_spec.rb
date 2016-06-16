require File.expand_path '../spec_helper.rb', __FILE__

describe 'VHost-API Application' do
  it 'allows accessing the home page' do
    get '/'
    expect(last_response).to be_ok
  end
end
