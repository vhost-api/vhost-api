# frozen_string_literal: true

require File.expand_path '../../spec_helper.rb', __FILE__

describe 'VHost-API Ipv4Address Model' do
  it 'has a valid factory' do
    expect(create(:ipv4address)).to be_valid
  end

  it 'is invalid without a ipv4address' do
    expect { create(:ipv4address, address: nil) }.to(
      raise_exception(DataMapper::SaveFailureError)
    )
  end

  it 'allows adding records' do
    _testipv4address = create(:ipv4address)
    expect(Ipv4Address.count).to eq(1)
  end

  it 'serializes to valid json' do
    testipv4address = build(:ipv4address)
    expect { JSON.parse(testipv4address.to_json) }.not_to raise_exception
  end

  it 'returns the owner as a User object' do
    _testadmin = create(:admin)
    testipv4address = create(:ipv4address)
    expect(testipv4address.owner).to be_an_instance_of(User)
  end
end
