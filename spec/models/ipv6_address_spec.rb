# frozen_string_literal: true

require File.expand_path('../spec_helper.rb', __dir__)

describe 'VHost-API Ipv6Address Model' do
  it 'has a valid factory' do
    expect(create(:ipv6address)).to be_valid
  end

  it 'is invalid without a ipv6address' do
    expect { create(:ipv6address, address: nil) }.to(
      raise_exception(DataMapper::SaveFailureError)
    )
  end

  it 'allows adding records' do
    _testipv6address = create(:ipv6address)
    expect(Ipv6Address.count).to eq(1)
  end

  it 'serializes to valid json' do
    testipv6address = build(:ipv6address)
    expect { JSON.parse(testipv6address.to_json) }.not_to raise_exception
  end

  it 'returns the owner as a User object' do
    _testadmin = create(:admin)
    testipv6address = create(:ipv6address)
    expect(testipv6address.owner).to be_an_instance_of(User)
  end
end
