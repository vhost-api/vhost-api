# frozen_string_literal: true
require File.expand_path '../../spec_helper.rb', __FILE__

describe 'VHost-API Domain Model' do
  it 'has a valid factory' do
    expect(create(:domain)).to be_valid
  end

  it 'is invalid without a name' do
    expect { create(:domain, name: nil) }.to(
      raise_exception(DataMapper::SaveFailureError)
    )
  end

  it 'allows adding records' do
    _testdomain = create(:domain)
    expect(Domain.count).to eq(1)
  end

  it 'serializes to valid json' do
    testdomain = build(:domain)
    expect { JSON.parse(testdomain.to_json) }.not_to raise_exception
  end

  it 'returns the owner as a User object' do
    _testadmin = create(:admin)
    test = create(:domain)
    expect(test.owner).to be_an_instance_of(User)
  end

  it 'returns a serializable hash from the customer method' do
    testdomain = build(:domain)
    expect { JSON.parse(testdomain.customer.to_json) }.not_to raise_exception
  end
end
