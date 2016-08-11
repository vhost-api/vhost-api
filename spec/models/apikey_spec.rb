# frozen_string_literal: true
require File.expand_path '../../spec_helper.rb', __FILE__

describe 'VHost-API Apikey Model' do
  it 'has a valid factory' do
    expect(create(:apikey)).to be_valid
  end

  it 'is invalid without an apikey' do
    expect { create(:apikey, apikey: nil) }.to(
      raise_exception(DataMapper::SaveFailureError)
    )
  end

  it 'allows adding records' do
    _testapikey = create(:apikey)
    expect(Apikey.count).to eq(1)
  end

  it 'serializes to valid json' do
    testapikey = build(:apikey)
    expect { JSON.parse(testapikey.to_json) }.not_to raise_exception
  end

  it 'returns the owner as a User object' do
    _testadmin = create(:admin)
    test = create(:apikey)
    expect(test.owner).to be_an_instance_of(User)
  end

  it 'returns a serializable hash from the customer method' do
    testapikey = build(:apikey)
    expect { JSON.parse(testapikey.customer.to_json) }.not_to raise_exception
  end
end
