# frozen_string_literal: true
require File.expand_path '../../spec_helper.rb', __FILE__

describe 'VHost-API MailAlias Model' do
  it 'has a valid factory' do
    expect(create(:mailalias)).to be_valid
  end

  it 'is invalid without an address' do
    expect { create(:mailalias, address: nil) }.to(
      raise_exception(DataMapper::SaveFailureError)
    )
  end

  it 'allows adding records' do
    _testmailalias1 = create(:mailalias)
    _testmailalias2 = create(:mailalias)
    expect(MailAlias.count).to eq(2)
  end

  it 'serializes to valid json' do
    testmailalias = build(:mailalias)
    expect { JSON.parse(testmailalias.to_json) }.not_to raise_exception
  end

  it 'returns the owner as a User object' do
    _testadmin = create(:admin)
    test = create(:mailalias)
    expect(test.owner).to be_an_instance_of(User)
  end
end
