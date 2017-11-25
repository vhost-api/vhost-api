# frozen_string_literal: true

require File.expand_path '../../spec_helper.rb', __FILE__

describe 'VHost-API MailForwarding Model' do
  it 'has a valid factory' do
    expect(create(:mailforwarding)).to be_valid
  end

  it 'is invalid without an address' do
    expect { create(:mailforwarding, address: nil) }.to(
      raise_exception(DataMapper::SaveFailureError)
    )
  end

  it 'allows adding records' do
    _testmailforwarding1 = create(:mailforwarding)
    _testmailforwarding2 = create(:mailforwarding)
    expect(MailForwarding.count).to eq(2)
  end

  it 'serializes to valid json' do
    testmailforwarding = build(:mailforwarding)
    expect { JSON.parse(testmailforwarding.to_json) }.not_to raise_exception
  end

  it 'returns the owner as a User object' do
    _testadmin = create(:admin)
    test = create(:mailforwarding)
    expect(test.owner).to be_an_instance_of(User)
  end
end
