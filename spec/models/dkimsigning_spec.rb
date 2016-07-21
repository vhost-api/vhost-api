# frozen_string_literal: true
require File.expand_path '../../spec_helper.rb', __FILE__

describe 'VHost-API DkimSigning Model' do
  it 'has a valid factory' do
    expect(create(:dkimsigning)).to be_valid
  end

  it 'is invalid without an author' do
    expect { create(:dkimsigning, author: nil) }.to(
      raise_exception(DataMapper::SaveFailureError)
    )
  end

  it 'allows adding records' do
    _testdkimsigning = create(:dkimsigning)
    expect(DkimSigning.count).to eq(1)
  end

  it 'serializes to valid json' do
    testdkimsigning = build(:dkimsigning)
    expect { JSON.parse(testdkimsigning.to_json) }.not_to raise_exception
  end

  it 'returns the owner as a User object' do
    _testadmin = create(:admin)
    test = create(:dkimsigning)
    expect(test.owner).to be_an_instance_of(User)
  end
end
