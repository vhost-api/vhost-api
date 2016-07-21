# frozen_string_literal: true
require File.expand_path '../../spec_helper.rb', __FILE__

describe 'VHost-API Dkim Model' do
  it 'has a valid factory' do
    expect(create(:dkim)).to be_valid
  end

  it 'is invalid without a selector' do
    expect { create(:dkim, selector: nil) }.to(
      raise_exception(DataMapper::SaveFailureError)
    )
  end

  it 'allows adding records' do
    _testdkim = create(:dkim)
    expect(Dkim.count).to eq(1)
  end

  it 'serializes to valid json' do
    testdkim = build(:dkim)
    expect { JSON.parse(testdkim.to_json) }.not_to raise_exception
  end

  it 'returns the owner as a User object' do
    _testadmin = create(:admin)
    test = create(:dkim)
    expect(test.owner).to be_an_instance_of(User)
  end
end
