# frozen_string_literal: true
require File.expand_path '../../spec_helper.rb', __FILE__

describe 'VHost-API MailAccount Model' do
  it 'has a valid factory' do
    expect(create(:mailaccount)).to be_valid
  end

  it 'is invalid without an email' do
    expect { create(:mailaccount, email: nil) }.to(
      raise_exception(DataMapper::SaveFailureError)
    )
  end

  it 'allows adding records' do
    _testmailaccount1 = create(:mailaccount)
    _testmailaccount2 = create(:mailaccount)
    expect(MailAccount.count).to eq(2)
  end

  it 'allows adding accounts with multiple aliases/sources' do
    _testmailaccount = create(:mailaccount_with_aliases_and_sources)
    expect(MailAccount.count).to eq(1)
  end

  it 'serializes to valid json' do
    testmailaccount = build(:mailaccount)
    expect { JSON.parse(testmailaccount.to_json) }.not_to raise_exception
  end

  it 'returns the owner as a User object' do
    _testadmin = create(:admin)
    test = create(:mailaccount)
    expect(test.owner).to be_an_instance_of(User)
  end
end
