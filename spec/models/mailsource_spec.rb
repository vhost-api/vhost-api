# frozen_string_literal: true

require File.expand_path('../spec_helper.rb', __dir__)

describe 'VHost-API MailSource Model' do
  it 'has a valid factory' do
    expect(create(:mailsource)).to be_valid
  end

  it 'is invalid without an address' do
    expect { create(:mailsource, address: nil) }.to(
      raise_exception(DataMapper::SaveFailureError)
    )
  end

  it 'allows adding records' do
    _testmailsource1 = create(:mailsource)
    _testmailsource2 = create(:mailsource)
    expect(MailSource.count).to eq(2)
  end

  it 'serializes to valid json' do
    testmailsource = build(:mailsource)
    expect { JSON.parse(testmailsource.to_json) }.not_to raise_exception
  end

  it 'returns the owner as a User object' do
    _testadmin = create(:admin)
    test = create(:mailsource)
    expect(test.owner).to be_an_instance_of(User)
  end
end
